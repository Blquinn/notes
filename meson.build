project('notes', ['c', 'vala'],
          version: '0.1.0',
    meson_version: '>= 0.50.0',
  default_options: [ 'warning_level=2',
                   ],
)

i18n = import('i18n')
add_project_arguments('-DGETTEXT_PACKAGE="notes"', language: 'c')
# i18n.gettext(meson.project_name(),
#   args: '--directory=' + meson.source_root() + '/po')

subdir('data')
subdir('src')
subdir('po')

meson.add_install_script('build-aux/meson/postinstall.py')
