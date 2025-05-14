# File: templates/html_components.py

def app_header(title="Country Currency Management", 
               subtitle="A comprehensive system for managing country and currency mappings"):
    """Render the application header"""
    return f"""
    <h1>
        <span style="color: #4da6ff;">🌎</span> 
        {title}
    </h1>
    
    <p style="text-align: center; margin-bottom: 30px;">
        {subtitle}
    </p>
    """

def section_header(icon, title):
    """Render a section header with icon"""
    return f"""
    <div class="section-header">
        <div class="section-header-icon">{icon}</div>
        <h2>{title}</h2>
    </div>
    """

def card_start():
    """Start a card container"""
    return '<div class="card">'

def card_end():
    """End a card container"""
    return '</div>'

def field_label(label, help_text=None):
    """Render a field label with optional help text"""
    html = f'<div class="field-label">{label}</div>'
    if help_text:
        html += f'<div class="field-help">{help_text}</div>'
    return html

def tooltip_field(label, tooltip_text):
    """Render a field with tooltip"""
    return f"""
    <div class="tooltip">{label}
        <span class="tooltiptext">{tooltip_text}</span>
    </div>
    """

def success_message(message):
    """Render a success message"""
    return f"""
    <div class="success-message">
        <strong>Success!</strong> {message}
    </div>
    """

def error_message(message):
    """Render an error message"""
    return f"""
    <div class="error-message">
        <strong>Error!</strong> {message}
    </div>
    """

def dataframe_container_start(border_color=None):
    """Start a dataframe container with optional border color"""
    style = f'border: 2px solid {border_color};' if border_color else ''
    return f'<div class="dataframe-container" style="{style}">'

def dataframe_container_end():
    """End a dataframe container"""
    return '</div>'

def footer(version="v1.0.0"):
    """Render the application footer"""
    return f"""
    <div style="text-align: center; margin-top: 50px; padding-top: 20px; border-top: 1px solid #444444;">
        <p style="color: #7f8c8d; font-size: 14px;">
            Country Currency Database © {2025} | Built with Streamlit 
            <span style="color: #4da6ff;">{version}</span>
        </p>
    </div>
    """

def delete_warning():
    """Render a delete warning message"""
    return """
    <div class="warning-message">
        <strong>Warning:</strong> Deleting an entry is permanent and cannot be undone.
    </div>
    """

def delete_confirmation():
    """Render a delete confirmation message"""
    return """
    <div class="confirmation-message">
        <strong>Confirmation Required</strong>
        <p>Please confirm that you want to permanently delete this entry.</p>
    </div>
    """

def info_box(message, title="Information"):
    """Render an info box"""
    return f"""
    <div class="info-box">
        <div class="info-box-title">{title}</div>
        <div class="info-box-content">{message}</div>
    </div>
    """

def loader():
    """Render a loading spinner"""
    return """
    <div class="loader-container">
        <div class="loader"></div>
        <p>Loading data...</p>
    </div>
    """
