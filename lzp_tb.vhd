library ieee;
use ieee.std_logic_1164.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
entity lzp_tb is
end lzp_tb;
 
architecture behavior of lzp_tb is
	component lzp
	generic(
		n: natural
	);
	port(
		x : in std_logic_vector(7 downto 0);
		y : in std_logic_vector(7 downto 0);
		count : out std_logic_vector(3 downto 0)
	);
	end component;
	
	signal x : std_logic_vector(7 downto 0) := (others => '0');
	signal y : std_logic_vector(7 downto 0) := (others => '0');
	signal count : std_logic_vector(3 downto 0);
	signal clk : std_logic;
	constant clk_period : time := 10 ns;
	
begin
	
	uut: lzp
	generic map(
		n => 8
	)
	port map(
		x => x,
		y => y,
		count => count
	);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;
		for i in 0 to 100 loop
			x <= std_logic_vector(unsigned(x) + 2);
			y <= std_logic_vector(unsigned(y) + 5);
			wait for clk_period*10;
		end loop;

   end process;

END;
