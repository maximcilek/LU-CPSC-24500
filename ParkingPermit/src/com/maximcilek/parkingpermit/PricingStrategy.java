package com.maximcilek.parkingpermit;

import java.math.BigDecimal;

public interface PricingStrategy {
	BigDecimal computeMonthly(PermitSelection selection);
}
