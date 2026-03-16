package com.maximcilek.parkingpermit;

import java.math.BigDecimal;

//formats display
public final class Receipt {
	public static void print(PermitSelection selection, BigDecimal monthly, BigDecimal subtotal, BigDecimal campusFee, BigDecimal total) {
        System.out.println("---- Parking Permit Receipt ----");
        System.out.println("Permit Type: " + selection.getPermitType());
        System.out.println("Vehicle Type: " + selection.getVehicleType());
        System.out.println("Carpool: " + (selection.isCarpool() ? "Yes" : "No"));
        System.out.println("Months: " + selection.getMonths());
        System.out.println("Monthly Rate: $" + monthly);
        System.out.println("Subtotal: $" + subtotal);
        System.out.println("Campus Fee (5%): $" + campusFee);
        System.out.println("Total: $" + total);
        System.out.println("-------------------------------");
    }
}
