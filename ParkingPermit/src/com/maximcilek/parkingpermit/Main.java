package com.maximcilek.parkingpermit;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class Main {

	public static void main(String[] args) {
		System.out.println("\n=====================================================================");
		System.out.println("\nWelcome to the Parking Permit Application!\n");
		System.out.println("=====================================================================\n");
		Scanner scanner = new Scanner(System.in);

        while (true) {
            try {
                System.out.println("Select Permit Type (RESIDENT/COMMUTER): ");
                PermitType permitType = PermitType.valueOf(scanner.nextLine().trim().toUpperCase());

                System.out.println("Select Vehicle Type (CAR/SUV/MOTORCYCLE): ");
                VehicleType vehicleType = VehicleType.valueOf(scanner.nextLine().trim().toUpperCase());
                

                System.out.println("Carpool? (Y/N): ");
                boolean carpool = scanner.nextLine().trim().equalsIgnoreCase("Y");

                System.out.println("Number of Months (1-12): ");
                int months = Integer.parseInt(scanner.nextLine().trim());

                PermitSelection selection = new PermitSelection(permitType, vehicleType, carpool, months);

                // Choose PricingStrategy polymorphically
                PricingStrategy strategy = switch (permitType) {
                    case RESIDENT -> new ResidentPricingStrategy();
                    case COMMUTER -> new CommuterPricingStrategy();
                };

                List<RateModifier> modifiers = new ArrayList<>();
                modifiers.add(vehicleType); // VehicleType implements RateModifier
                if (carpool) modifiers.add(new CarpoolDiscount());

                PricingPipeline pipeline = new PricingPipeline(modifiers);
                PricingCalculator calculator = new PricingCalculator(strategy, pipeline);

                BigDecimal monthly = pipeline.applyAll(strategy.computeMonthly(selection));
                BigDecimal subtotal = calculator.calculateSubtotal(selection);
                BigDecimal fee = calculator.calculateCampusFee(selection);
                BigDecimal total = calculator.calculateTotal(selection);

                Receipt.print(selection, monthly, subtotal, fee, total);

                break; // exit after successful run

            } catch (IllegalArgumentException e) {
                System.out.println("Invalid input. Try again.");
            } catch (InvalidSelectionException e) {
                System.out.println(e.getMessage());
            }
        }

        scanner.close();
	}
}