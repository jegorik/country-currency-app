# UI Styles

This directory contains CSS styling for the Country Currency App's Streamlit UI.

## Files

- `style.css` - Main stylesheet for the application containing all custom styling

## Usage

The CSS is loaded in the main application file (`app_new.py`) using:

```python
# Load custom CSS
css_path = os.path.join(os.path.dirname(__file__), "ui", "styles", "style.css")
with open(css_path, 'r') as f:
    st.markdown(f'<style>{f.read()}</style>', unsafe_allow_html=True)
```

## Style Classes

The stylesheet contains several custom classes for styling different components:

- `.card` - Styling for card containers
- `.section-header` - Styling for section headers
- `.success-message`, `.error-message`, `.warning-message` - Styling for different alert types
- `.field-label`, `.field-help` - Styling for form field labels and help text
- `.app-header`, `.app-title`, `.app-subtitle` - Styling for the application header
- `.app-footer` - Styling for the application footer

And many more utility classes for consistent styling throughout the application.
