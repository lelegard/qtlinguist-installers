## Standalone binary installers for Qt Linguist

### Qt Linguist

[Qt](https://www.qt.io/) is a powerful portable development environment.
Qt applications are easily translatable. Developers typically write their
applications in English but all strings which are visible to the end-user
can be automatically grabbed and stored in *translation files* with
suffix `.ts`. See more details [here](http://doc.qt.io/qt-5/internationalization.html).

The translation files are then passed to various *translators* who are fluent
in the target languages. Using a user-friendly tool, *Qt Linguist*, the translators
produce the translations from the English strings in their native language.

The tool Qt Linguist is installed with the complete Qt development environment.
The binary installer for this environment is 1 GB big and a typical installation
uses 4 GB of disk space.

This is acceptable for developers. But translators are not developers. They may even
have no technical skill at all. The only tool they need from the rich Qt environment
is Linguist. Asking them to download and install 1 GB of Qt SDK is not acceptable for
most of them.

So, having a solution to download and install Qt Linguist only is a legitimate
requirement for translators. However, there is no official standalone installer
for Qt Linguist available from the Qt project.

Since such installers are real requirements, custom binary installers for Qt Linguist
are available from many third-party download sites. However, there is a security issue
here. We have no guarantee that the application they install is genuine and free of malware.

### The project `qtlinguist-installers`

The purpose of [this project](https://github.com/lelegard/qtlinguist-installers/)
is to provide Open Source scripts to rebuild standalone binary installers for
Qt Linguist from a standard installation of the Qt environment.

This solves the security issue for technical companies or independent developers
who develop Qt software and delegate the internationalization of their applications
to non-technical translators. The technical developer can thus create his own
binary installers for Qt Linguist using his own trustable environment and later
deliver these installers to the translators.

Alternatively, if you trust the author of this project, you may directly download
binary installers from the [project releases](https://github.com/lelegard/qtlinguist-installers/releases).

As an example, a standalone binary installer for Qt Linguist on Windows is 17 MB
big and uses 33 MB of disk space after installation. Compare this to 1 GB of
installer and 4 GB of disk space for the complete Qt environment.

### Target environments

This project provides installers for Windows and Mac OS, the two main working
environments for non-technical translators.

Most Linux distros provide a segmented installation of the Qt environment,
many small packages with dependency management, instead of a huge
global Qt installer. In this context, installing Qt Linguist only is
probably already available.
