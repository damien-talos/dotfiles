# zsh startup file order:
# $ZDOTDIR/.zshenv
# $ZDOTDIR/.zprofile    <-- We are here right now
# $ZDOTDIR/.zshrc
# $ZDOTDIR/.zlogin
# $ZDOTDIR/.zlogout

[ -d '/Volumes/RAMDisk' ] || hdiutil attach -nomount ram://16777216 | xargs diskutil erasevolume HFS+ "RAMDisk"
