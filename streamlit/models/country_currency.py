"""
Country-Currency data model classes.
"""

class CountryCurrency:
    """Model class for a country-currency record."""
    
    def __init__(
        self,
        country_code: str,
        country_number: int,
        country: str,
        currency_name: str,
        currency_code: str,
        currency_number: int
    ):
        """Initialize a country-currency record."""
        self.country_code = country_code
        self.country_number = country_number
        self.country = country
        self.currency_name = currency_name
        self.currency_code = currency_code
        self.currency_number = currency_number
    
    @classmethod
    def from_dict(cls, data: dict) -> 'CountryCurrency':
        """Create a CountryCurrency instance from a dictionary."""
        return cls(
            country_code=data.get('country_code'),
            country_number=data.get('country_number'),
            country=data.get('country'),
            currency_name=data.get('currency_name'),
            currency_code=data.get('currency_code'),
            currency_number=data.get('currency_number')
        )
    
    def to_dict(self) -> dict:
        """Convert the model to a dictionary."""
        return {
            'country_code': self.country_code,
            'country_number': self.country_number,
            'country': self.country,
            'currency_name': self.currency_name,
            'currency_code': self.currency_code,
            'currency_number': self.currency_number
        }
    
    def __str__(self) -> str:
        """String representation of the model."""
        return f"{self.country} ({self.country_code}) - {self.currency_name} ({self.currency_code})"
