package com.maximcilek.parkingpermit;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

// uses a PricingStrategy and a PricingPipeline to compute subtotal/fee/total
public final class PricingCalculator {
	private static final BigDecimal CAMPUS_FEE = BigDecimal.valueOf(0.05); // 5%

    private final PricingStrategy strategy;
    private final PricingPipeline pipeline;

    public PricingCalculator(PricingStrategy strategy, PricingPipeline pipeline) {
        this.strategy = strategy;
        this.pipeline = pipeline;
    }

    public BigDecimal calculateTotal(PermitSelection selection) {
        selection.validate();
        BigDecimal monthly = strategy.computeMonthly(selection);
        BigDecimal modifiedMonthly = pipeline.applyAll(monthly);
        BigDecimal subtotal = modifiedMonthly.multiply(BigDecimal.valueOf(selection.getMonths()));
        BigDecimal fee = subtotal.multiply(CAMPUS_FEE).setScale(2, RoundingMode.HALF_UP);
        return subtotal.add(fee).setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal calculateSubtotal(PermitSelection selection) {
        BigDecimal monthly = strategy.computeMonthly(selection);
        BigDecimal modifiedMonthly = pipeline.applyAll(monthly);
        return modifiedMonthly.multiply(BigDecimal.valueOf(selection.getMonths())).setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal calculateCampusFee(PermitSelection selection) {
        return calculateSubtotal(selection).multiply(CAMPUS_FEE).setScale(2, RoundingMode.HALF_UP);
    }
}
