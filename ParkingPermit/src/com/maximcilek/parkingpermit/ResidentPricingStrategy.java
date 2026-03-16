package com.maximcilek.parkingpermit;

import java.math.BigDecimal;

public class ResidentPricingStrategy implements PricingStrategy {
	private static final BigDecimal RATE = BigDecimal.valueOf(45.00);
	
	@Override
    public BigDecimal computeMonthly(PermitSelection selection) {
        return RATE;
    }
}
