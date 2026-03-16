package com.maximcilek.parkingpermit;

import java.math.BigDecimal;
import java.math.RoundingMode;

public class CommuterPricingStrategy implements PricingStrategy {
	private static final BigDecimal RATE = BigDecimal.valueOf(35.00);
    private static final BigDecimal DISCOUNT = BigDecimal.valueOf(0.85); // 15% off

    @Override
    public BigDecimal computeMonthly(PermitSelection selection) {
        return RATE.multiply(DISCOUNT).setScale(2, RoundingMode.HALF_UP);
    }
}
