THEME='themes/sensuikan1973_theme.css'
SRC='slide.md'
OUTPUT='dist/slide.pdf'

# See: https://github.com/marp-team/marp-cli#metadata
OG_TITLE='Flutter_FFI_sensuikan1973'
OG_DESCRIPTION='「FFI in Flutter」 at Flutter Meetup Tokyo'
OG_URL='' # FIXME: Netlify の URL を書く
OG_IMAGE='https://pbs.twimg.com/profile_images/1036981510543355904/oqyXbAEg_400x400.jpg'

marp --html $SRC --pdf --allow-local-files --output $OUTPUT \
--theme $THEME \
--title $OG_TITLE \
--description $OG_DESCRIPTION \
--url $OG_URL \
--og-image $OG_IMAGE
