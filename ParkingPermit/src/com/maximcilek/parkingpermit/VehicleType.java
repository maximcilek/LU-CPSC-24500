package com.maximcilek.parkingpermit;

import java.math.BigDecimal;
import java.math.RoundingMode;

public enum VehicleType implements RateModifier {
    CAR(BigDecimal.valueOf(1.0)),
    SUV(BigDecimal.valueOf(1.15)),
    MOTORCYCLE(BigDecimal.valueOf(0.7));

    private final BigDecimal multiplier;

    VehicleType(BigDecimal multiplier) {
        this.multiplier = multiplier;
    }

    @Override
    public BigDecimal apply(BigDecimal currentMonthly) {
        return currentMonthly.multiply(multiplier).setScale(2, RoundingMode.HALF_UP);
    }
}