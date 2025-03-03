# CLAUDE.md - Guidance for Elizabeth Wedding Site

## Commands

- Update slideshow with images: `./update_images.sh photos/ index.html`
- Generate test images: `./generate_test_images.sh test_photos/ index.html [count]`
- Preview site locally: `python -m http.server` (then visit http://localhost:8000)

## Code Style

### HTML
- Use HTML5 semantics
- Indentation: 4 spaces
- CSS variables for colors and fonts (--main-color, --accent-color, etc.)
- Comment markers for dynamic sections: `<!--SECTION_START-->` and `<!--SECTION_END-->`

### JavaScript
- Use vanilla JS (no frameworks)
- camelCase for variables and functions
- Indentation: 4 spaces
- setTimeout for slideshow timing (4 seconds per slide)

### Shell Scripts
- Include usage instructions as comments
- Error handling with appropriate exit codes
- Use temporary files with mktemp
- Backup files before modifying (.bak extension)

Maintain the elegant, minimal aesthetic of the wedding site with Cormorant Garamond font and the established color scheme.