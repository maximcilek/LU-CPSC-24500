"""
package edu.lewis.library_demo;

public class LibraryItem {
    private String title;
    private String itemId;
    private boolean checkedOut;

    public LibraryItem(String title, String itemId) {
        this.title = title;
        this.itemId = itemId;
        this.checkedOut = false;
    }

    public String getTitle() {
        return title;
    }

    public String getItemId() {
        return itemId;
    }

    public boolean isCheckedOut() {
        return checkedOut;
    }

    public boolean checkOut() {
        if (!checkedOut) {
            checkedOut = true;
            return true;
        }
        return false;
    }

    public boolean returnItem() {
        if (checkedOut) {
            checkedOut = false;
            return true;
        }
        return false;
    }

    @Override
    public String toString() {
        return "Title: " + title +
               "\nItem ID: " + itemId +
               "\nChecked Out: " + checkedOut;
    }
}
"""

class LibraryItem:
    def __init__(self, title, item_id):
        self.title = title
        self.item_id = item_id
        self.checked_out = False
    
    @property
    def title(self) -> str:
        return self._title
    
    @property
    def item_id(self) -> str:
        return self._item_id
    
    @property
    def checked_out(self) -> bool:
        return self._checked_out

    @title.setter
    def title(self, value: str) -> None:
        field_name = type(self).title.fset.__name__
        if not isinstance(value, str) or not value.strip():
            raise ValueError(f"{self.__class__.__name__} {field_name} must be a non-empty string, got {value}")
        self._title = value
    
    @item_id.setter
    def item_id(self, value: str) -> None:
        field_name = type(self).item_id.fset.__name__
        if not isinstance(value, str) or not value.strip():
            raise ValueError(f"{self.__class__.__name__} {field_name} must be a non-empty string, got {value}")
        self._item_id = value

    @checked_out.setter
    def checked_out(self, value: bool) -> None:
        field_name = type(self).checked_out.fset.__name__
        if not isinstance(value, bool):
            raise ValueError(f"{self.__class__.__name__} {field_name} must be a bool, got {value!r}")
        self._checked_out = value

    def is_checked_out(self) -> bool:
        return self.checked_out

    def check_out(self) -> bool:
        if not self.checked_out:
            self.checked_out = True
            return True
        return False

    def return_item(self) -> bool:
        if self.checked_out:
            self.checked_out = False
            return True
        return False

    def __repr__(self):
        return f"{self.__class__.__name__}(Title={self.title!r}, Item ID={self.item_id!r}, Checked Out={self.checked_out!r})"
    def __str__(self):
        return f"Title: {self.title}\nItem ID: {self.item_id}\nChecked Out: {self.checked_out}"