library ieee;
use work.tools.all;
use ieee.std_logic_1164.all;

entity lzp is
	generic(
		n : natural
	);
	port(
		x : in std_logic_vector(n - 1 downto 0);
		y : in std_logic_vector(n - 1 downto 0);
		count : out std_logic_vector(flog2(n) downto 0)
	);
end lzp;

architecture Behavioral of lzp is
	constant tree_size : integer := flog2(n);
	constant tree2_size : integer := clog2(1 + (n / 3));
	constant m : integer := flog2(n);
	
	type state is (s_A, s_P, s_G, s_N);
	type intermediate_result is array(n - 1 downto 0) of state;
	type stage_type is array(tree_size + tree2_size downto 0) of intermediate_result;
	
	type SignalTable is array (tree_size + tree2_size downto 0) of std_logic_vector(n downto 1);
	signal g : SignalTable;
	signal p : SignalTable;
	
	signal result : std_logic_vector(n - 1 downto 0);
	signal carry_out : std_logic;
begin
	
	tree: process(x, y, g, p)
		variable step : integer;
		variable l, r : state;
		variable is_last : boolean;
		variable stage : stage_type;
		variable output : std_logic_vector(n - 1 downto 0);
		variable one_of_n : std_logic_vector(n - 1 downto 0);
		variable temp : std_logic;
		variable suggestion : std_logic_vector(m downto 0);
	begin
		-- BRENT-KUNG CARRY PROPAGATION
		
		-- generate g and p signals
		for i in 0 to n - 1 loop
			g(0)(i + 1) <= x(i) and y(i);
			p(0)(i + 1) <= x(i) xor y(i);
		end loop;
		
		-- first tree
		for j in 0 to tree_size - 1 loop
			for i in 1 to n loop
				if (i mod 2**(j+1) = 0) then
					g(j + 1)(i) <= g(j)(i) or (g(j)(i - 2**j) and p(j)(i));
					p(j + 1)(i) <= p(j)(i) and p(j)(i - 2**j);
				else
					g(j + 1)(i) <= g(j)(i);
					p(j + 1)(i) <= p(j)(i);
				end if;
			end loop;
		end loop;
		
		-- second tree (somewhat more complicated)
		for j in tree_size to tree_size + tree2_size - 1 loop
			step := 2**(tree2_size - 1 - (j - tree_size));
			for i in 1 to n loop
				if ((i >= 3 * step) and (i - 3 * step) mod (2 * step) = 0) then
					g(j + 1)(i) <= g(j)(i) or (g(j)(i - step) and p(j)(i));
					p(j + 1)(i) <= p(j)(i) and p(j)(i - step);
				else
					g(j + 1)(i) <= g(j)(i);
					p(j + 1)(i) <= p(j)(i);
				end if;
			end loop;
		end loop;
		
		-- sum bit and carry out generation
		result(0) <= p(tree_size + tree2_size)(1);
		for i in 1 to n - 1 loop
			result(i) <= p(0)(i + 1) xor g(tree_size + tree2_size)(i);
		end loop;
		
		
		
		-- BRENT-KUNG LEADING ZERO PREDICTION
	
		-- fill stage 0
		for i in 0 to n - 1 loop
			if x(i) = '0' and y(i) = '0' then
				stage(0)(i) := s_A;
			elsif x(i) = '1' and y(i) = '1' then
				stage(0)(i) := s_G;
			else
				stage(0)(i) := s_P;
			end if;
		end loop;
		
		-- first tree
		for j in 0 to tree_size - 1 loop
			step := 2**j;
			for i in 0 to n - 1 loop
				if (i mod (2 * step) = 0) then
					l := stage(j)(i + step);
					r := stage(j)(i);
					if l = s_A and r = s_A then
						stage(j + 1)(i) := s_A;
					elsif l = s_P and r = s_P then
						stage(j + 1)(i) := s_P;
					elsif l = s_P and r = s_G then
						stage(j + 1)(i) := s_G;
					elsif l = s_G and r = s_A then
						stage(j + 1)(i) := s_G;
					else
						stage(j + 1)(i) := s_N;
					end if;
				else
					stage(j + 1)(i) := stage(j)(i);
				end if;
			end loop;
		end loop;
		
		-- second tree
		for j in tree_size to tree_size + tree2_size - 1 loop
			step := 2**(tree2_size - 1 - (j - tree_size));
			for i in 0 to n - 1 loop
				is_last := i = ((n - 1) / step * step);
				if (i mod (2 * step) = step) and not(is_last) then
					l := stage(j)(i + step);
					r := stage(j)(i);
					if l = s_A and r = s_A then
						stage(j + 1)(i) := s_A;
					elsif l = s_P and r = s_P then
						stage(j + 1)(i) := s_P;
					elsif l = s_P and r = s_G then
						stage(j + 1)(i) := s_G;
					elsif l = s_G and r = s_A then
						stage(j + 1)(i) := s_G;
					else
						stage(j + 1)(i) := s_N;
					end if;
				else
					stage(j + 1)(i) := stage(j)(i);
				end if;
			end loop;
		end loop;

		if (stage(tree_size + tree2_size)(0) = s_N) then
			output(0) := '0';
		else
			output(0) := '1';
		end if;

		for i in 1 to n - 1 loop
			if (stage(tree_size + tree2_size)(i) = s_N or
			   (stage(tree_size + tree2_size)(i) = s_A and g(tree_size + tree2_size)(i) = '1')) then
				output(i) := '0';
			else
				output(i) := '1';
			end if;
		end loop;
		
		one_of_n(0) := output(0);
		for i in 1 to n - 1 loop
			one_of_n(i) := output(i) xor output(i - 1);
		end loop;
		
		step := 1;
		for i in 0 to m loop
			temp := '0';
			for j in 0 to n - 1 loop
				if (n - j) mod (step * 2) >= step then
					temp := temp or one_of_n(j);
				end if;
			end loop;
			suggestion(i) := temp;
			step := step * 2;
		end loop;
		
		if (stage(tree_size + tree2_size)(n - 1) = s_P and g(tree_size + tree2_size)(n - 1) = '0') then
			count <= (others => '0');
		else
			count <= suggestion;
		end if;
		
	end process tree;
end Behavioral;

