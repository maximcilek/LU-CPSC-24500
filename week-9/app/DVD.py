"""
package edu.lewis.library_demo;

public class DVD extends LibraryItem {
    private int duration;

    public DVD(String title, String itemId, int duration) {
        super(title, itemId);
        this.duration = duration;
    }

    public int getDuration() {
        return duration;
    }

    @Override
    public String toString() {
        return super.toString() +
               "\nDuration: " + duration + " minutes";
    }
}
"""

from LibraryItem import LibraryItem

class DVD(LibraryItem):
    def __init__(self, title, item_id, duration):
        super().__init__(title, item_id)
        self.duration = duration

    @property
    def duration(self) -> int:
        return self._duration

    @duration.setter
    def duration(self, value: int) -> None:
        field_name = type(self).duration.fset.__name__
        if not isinstance(value, int):
            raise ValueError(f"{self.__class__.__name__} {field_name} must be an integer, got {value!r}")
        if value <= 0:
            raise ValueError(f"{self.__class__.__name__} {field_name} must be a positive integer, got {value!r}")
        self._duration = value
    
    def __repr__(self):
        return f"{self.__class__.__name__}(Title={self.title!r}, Item ID={self.item_id!r}, Duration={self.duration!r})"
    def __str__(self):
        return f"{super().__str__()}\nDuration: {self.duration!r} minutes"