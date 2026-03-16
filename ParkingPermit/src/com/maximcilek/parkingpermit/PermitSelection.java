package com.maximcilek.parkingpermit;

// fields: permit, vehicle, carpool, months; validate() throws InvalidSelectionException
public final class PermitSelection implements Validatable {
	private final PermitType permitType;
    private final VehicleType vehicleType;
    private final boolean carpool;
    private final int months;

    public PermitSelection(PermitType permitType, VehicleType vehicleType, boolean carpool, int months) {
        this.permitType = permitType;
        this.vehicleType = vehicleType;
        this.carpool = carpool;
        this.months = months;
    }

    public PermitType getPermitType() { return permitType; }
    public VehicleType getVehicleType() { return vehicleType; }
    public boolean isCarpool() { return carpool; }
    public int getMonths() { return months; }

    @Override
    public void validate() throws InvalidSelectionException {
        if (months < 1 || months > 12) {
            throw new InvalidSelectionException("Months must be between 1 and 12.");
        }
    }
}
