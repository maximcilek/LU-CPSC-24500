package com.maximcilek.parkingpermit;

import java.math.BigDecimal;
import java.math.RoundingMode;

public class CarpoolDiscount  implements RateModifier {
	private static final BigDecimal DISCOUNT = BigDecimal.valueOf(0.9); // 10% off

    @Override
    public BigDecimal apply(BigDecimal currentMonthly) {
        return currentMonthly.multiply(DISCOUNT).setScale(2, RoundingMode.HALF_UP);
    }
}
