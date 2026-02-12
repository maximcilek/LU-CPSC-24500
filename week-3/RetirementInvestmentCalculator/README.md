# Retirement Investment Calculator

**Author:** Maxim Cilek

---

## Project Description
The **Retirement Investment Calculator** is a Java console application that simulates the growth of a retirement investment account over time. The program allows users to input personal and financial details (such as age, contributions, interest rate, and compounding frequency) and produces a year-by-year projection of account balances until retirement.

The simulation displays:
- Starting balance each year
- Total contributions for the year
- Interest earned for the year
- Ending balance for the year
- A final summary of total contributions, total interest earned, and ending balance at retirement

## Features
- Input validation for all numeric values
- Supports **annual, monthly, and daily compounding**
- Annual contribution growth support
- Clear, formatted table output
- Option to run multiple simulations in one program execution

## How to Run the Program

### Requirements
- Java JDK 17 or later
- Command-line environment or Java-compatible IDE (e.g., IntelliJ, Eclipse)

### Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/maximcilek/LU-CPSC-24500.git
   ```
2. Navigate to the source directory:
   ```bash
   cd LU-CPSC-24500/week-3/RetirementInvestmentCalculator/src
   ```
3. Compile the program:
   ```bash
   javac com/maximcilek/retirementcalculator/Main.java
   ```
4. Run the program:
   ```bash
   java com.maximcilek.retirementcalculator.Main
   ```

## Program Usage
When the program runs, the user is prompted to enter:
1. Current age
2. Retirement age
3. Current account balance
4. Annual contribution amount
5. Annual interest rate (APR)
6. Compounding frequency (Annually, Monthly, Daily)
7. Annual contribution increase percentage

After input is provided, the program prints a **year-by-year projection table** followed by a summary.  
The user may then choose to run another simulation or exit.

## Testing Methodology
The application was tested manually through repeated console runs using the [instructions](./Assignment%20--%20Retirement%20Investment%20Calculator.pdf).

- Validation loops ensure the program does not proceed until valid input is provided.
- Outputs were verified for logical correctness by checking contribution totals, interest calculations, and final balances.

## Notes
- The application is **console-based** and does not require any external libraries.
- All calculations follow the assignment’s specified [rules](./Assignment%20--%20Retirement%20Investment%20Calculator.pdf).

## License
This project was created for an academic programming assignment and is not licensed for commercial use.
