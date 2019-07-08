THEME='themes/sensuikan1973_theme.css'
SRC='slide.md'
OUTPUT='slide.pdf'

marp --html $SRC --pdf --allow-local-files --output $OUTPUT --theme $THEME
