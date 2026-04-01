"""
package edu.lewis.library_demo;

public class Book extends LibraryItem {
    private String author;

    public Book(String title, String itemId, String author) {
        super(title, itemId);
        this.author = author;
    }

    public String getAuthor() {
        return author;
    }

    @Override
    public String toString() {
        return super.toString() +
               "\nAuthor: " + author;
    }
}
"""

import re
from LibraryItem import LibraryItem

class Book(LibraryItem):
    def __init__(self, title, item_id, author):
        super().__init__(title, item_id)
        self.author = author
    
    @property
    def author(self) -> str:
        return self._author

    @author.setter
    def author(self, value: str) -> None:
        field_name = type(self).author.fset.__name__
        if not isinstance(value, str) or not value.strip():
            raise ValueError(f"{self.__class__.__name__} {field_name} must be a non-empty string, got {value}")
        
        # regex: allow letters, spaces, hyphens, apostrophes, periods
        pattern = r"^[A-Za-z .'-]+$"
        if not re.fullmatch(pattern, value.strip()):
            raise ValueError(f"{self.__class__.__name__} {field_name} contains invalid characters: {value!r}")
        self._author = value.strip()

    def __repr__(self):
        return f"{self.__class__.__name__}(Title={self.title!r}, Item ID={self.item_id!r}, Author={self.author!r})"
    def __str__(self):
        return f"{super().__str__()}\nAuthor: {self.author!r}"