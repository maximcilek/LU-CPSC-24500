package com.maximcilek.retirementcalculator;

import java.util.Scanner;
import java.text.NumberFormat;
import java.util.Locale;

enum Compounding {
	ANNUAL(1),
	MONTHLY(12),
	DAILY(365);
	private int periodsPerYear;
	private Compounding(int periods) { this.periodsPerYear = periods; }
	public int getPeriodsPerYear() { return periodsPerYear; }
}

public class Main {

	public static void main(String[] args) {
		System.out.println("\n=====================================================================");
		System.out.println("\nWelcome to the Retirement Investment Calculator!\n");
		System.out.println("=====================================================================\n");
		System.out.println("This program simulates the growth of your retirement account over time.");
		System.out.println("\nYou will be asked to provide the following inputs:");

		System.out.println("  1. Current Age: Enter your age in years (18 - 100)");
		System.out.println("  2. Retirement Age: Enter your desired retirement age (must be greater than current age, up to 100)");
		System.out.println("  3. Current Account Balance: Enter your current balance (must be 0 or greater)");
		System.out.println("  4. Annual Contribution: Enter the amount you plan to contribute each year (0 or greater)");
		System.out.println("  5. Annual Interest Rate (APR%): Enter the expected yearly interest rate (0% - 30%)");
		System.out.println("  6. Compounding Frequency: Select from the menu options");
		System.out.println("	1. Annually");
		System.out.println("	2. Monthly");
		System.out.println("	3. Daily");
		System.out.println("  7. Annual Contribution Increase (%): Enter expected yearly contribution growth (0% - 20%)");
		System.out.println("\nAfter entering these values, the program will display a table showing \nyearly balances, interest earned, and total contributions until your retirement age.");

		boolean run = true;
		Scanner sc = new Scanner(System.in);
		do {
			System.out.println("\n---------------------------------------------------------------------");
			System.out.println("User Input");
			System.out.println("---------------------------------------------------------------------");
			int currentAge = readIntInRange(sc, "Enter your current age:", 18, 100);
			int retirementAge = readIntInRange(sc, "Enter desired retirement age:", currentAge+1, 100);
			double currentBalance = readDoubleInRange(sc, "Enter current account balance:", 0, Double.POSITIVE_INFINITY);
			double annualContribution = readDoubleInRange(sc, "Enter annual contribution:", 0, Double.POSITIVE_INFINITY);
			double annualInterestRate = readDoubleInRange(sc, "Enter annual interest rate (APR%):", 0, 30);
			int compoundingFrequencyType = readCompoundingChoice(sc);
			double annualContributionIncrease = readDoubleInRange(sc, "Enter annual contribution increase (%):", 0, 20);
			runSimulation(annualContribution, annualContributionIncrease, annualInterestRate, compoundingFrequencyType, currentAge, currentBalance, retirementAge);
			run = askRunAgain(sc);
		} while (run == true);
		System.out.println("\n=====================================================================\n");
		System.out.println("Thank you for using the Retirement Investment Calculator, goodbye!\n");
		System.out.println("=====================================================================\n");
	}
	
	static int readIntInRange(Scanner sc, String prompt, int min, int max) {
		int value;
		do {
			System.out.print(prompt);
			try {
				value = Integer.parseInt(sc.nextLine());
			} catch (NumberFormatException e) {
				value = min-1;
			}
		} while (value < min || value > max);
		return value;
	}
	
	static double readDoubleInRange(Scanner sc, String prompt, double min, double max) {
		double value;
		do {
			System.out.print(prompt);
			try {
				value = Double.parseDouble(sc.nextLine());
			} catch (NumberFormatException e) {
				value = min-1;
				continue;
			}
			if (value < min) {
                System.out.println("Value must be at least " + min);
            } else if (value > max) {
                System.out.println("Value must be at most " + max);
            } else {
                break;
            }
		} while (true);
        return value;
	}
	
	static int readCompoundingChoice(Scanner sc) {
	    int value = 0;
	    do {
	        System.out.println("\nCompounding Frequency Options:");
	        System.out.println("    1. Annually");
	        System.out.println("    2. Monthly");
	        System.out.println("    3. Daily");
	        System.out.print("Enter compounding frequency menu number:");
	        try {
	            value = Integer.parseInt(sc.nextLine());
	        } catch (NumberFormatException e) {
	            System.out.println("Invalid input. Enter 1, 2, or 3.\n");
	            continue;
	        }
	    } while (value != 1 && value != 2 && value != 3);
	    return value;
	}

	static void runSimulation(double annualContribution, double annualContributionIncrease, double annualInterestRate, int compoundingFrequencyType, int currentAge, double currentBalance, int retirementAge) {
		System.out.println("\n---------------------------------------------------------------------");
		System.out.println("Running Simulation");
		System.out.println("---------------------------------------------------------------------");
		System.out.printf("%-4s | %-13s | %-13s | %-15s | %-13s%n", "Year", "Start Balance", "Contributions", "Interest Earned", "End Balance");
		
		Compounding c = switch(compoundingFrequencyType) {
		    case 1 -> Compounding.ANNUAL;
		    case 2 -> Compounding.MONTHLY;
		    case 3 -> Compounding.DAILY;
		    default -> Compounding.ANNUAL;
		};
		NumberFormat money = NumberFormat.getCurrencyInstance(Locale.US);
		double totalContributions = 0;
		double totalInterest = 0;
		int periodsPerYear = c.getPeriodsPerYear();
		double rPeriod = (annualInterestRate / 100.00) / periodsPerYear;
		for (int year=0; year < (retirementAge - currentAge); year++) {
			double startBalance = currentBalance;
			if (year > 0) {
				annualContribution *= (1 + annualContributionIncrease / 100.0);
				totalContributions += annualContribution;
			}
			double contributionPerPeriod = annualContribution / periodsPerYear;
			for (int p = 0; p < periodsPerYear; p++) {
				currentBalance += contributionPerPeriod;
				currentBalance *= (1 + rPeriod);
			}
			double interestEarned = currentBalance - startBalance - annualContribution;
			totalInterest += interestEarned;
			System.out.printf("%-4d | %-13s | %-13s | %-15s | %-13s%n", currentAge+year+1, money.format(startBalance), money.format(annualContribution), money.format(interestEarned), money.format(currentBalance));
		}
		System.out.println("---------------------------------------------------------------------");
		System.out.println("Summary");
		System.out.println("---------------------------------------------------------------------");
		System.out.println("Total Contributions: " + money.format(totalContributions));
		System.out.println("Total Interest Earned: " + money.format(totalInterest));
		System.out.println("End Balance at Age " + retirementAge + ": " + money.format(currentBalance));
	}
	
	static boolean askRunAgain(Scanner sc) {
		String response;
		do {
			System.out.print("\nWould you like to run another simulation (Y/N):");
			response = sc.nextLine().trim();
		} while (!response.equalsIgnoreCase("Y") && !response.equalsIgnoreCase("N"));
		
		if (response.equalsIgnoreCase("Y")) {
			return true;
		}
		return false;
	}
}