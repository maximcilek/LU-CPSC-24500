from Book import Book
from DVD import DVD

if __name__ == "__main__":
    book1 = Book("The Hobbit", "B101", "J.R.R. Tolkien")
    dvd1 = DVD("Inception", "D202", 148)

    print(f"Book Information:\n{book1}\n")
    print(f"DVD Information:\n{dvd1}\n")

    if book1.check_out():
        print(f"{book1.title} has been checked out.")
    else:
        print(f"{book1.title} is already checked out.")

    if book1.check_out():
        print(f"{book1.title} has been checked out.")
    else:
        print(f"{book1.title} is already checked out.")

    if book1.return_item():
        print(f"{book1.title} has been returned.")
    else:
        print(f"{book1.title} was not checked out.")

    if dvd1.check_out():
        print(f"\n{dvd1.title} has been checked out.")
    else:
        print(f"\n{dvd1.title}is already checked out.")

    print(f"\nUpdated DVD Information:\n{dvd1}")