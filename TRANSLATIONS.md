# TRANSLATIONS.md

The IRMA app currently exists in Dutch and English. If a user's phone is set to Dutch, the app will also be in Dutch. If their phone is set to any other language, our app will appear in English. To support additional languages, IRMA relies on contributions by members of the IRMA community. 

This file explains how to contribute and help to translate IRMA into new languages. It uses our translation into german (which currently is under review) as an example. It provides a "Quick" start" guide with the *technical* core instructions. For more detailed instructions and advice about the *translation process*, please look at our blog post [*"IRMA translations made easy"*](https://creativecode.github.io/irma-made-easy/posts/irma-translations-made-easy/). 

If you want to contribute, we assume you know the [IRMA app](https://irma.app) well, so you understand how and where texts are used in the app. We also assume you are comfortable with using *git* and editing `.json` and `.xml` files. No programming background is needed.   

If you want to contribute but have *no technical background*, please contact the IRMA team. Likewise, if you have questions or are unsure about a certain wording, don't hesitate to contact the IRMA community. The [IRMA slack](http://irmacard.slack.com) has a channel called `i18n`, which is dedicated to translations and other issues around internationalisation and localisation. 

## Quick start 

To translate IRMA into a new language, you need the following resources:
- Clone or fork the [irmamobile](https://github.com/privacybydesign/irmamobile) repository. 
- Clone or fork the [pbdf-schememanager](https://github.com/privacybydesign/pbdf-schememanager) repository

### Add the .json file 
Open the `irmamobile/assets/locales` folder. In here, you find a `.json`-file for each language. Copy and paste one of the files and rename it. In this file, keep all keys in place and translate all the values.

*Example*: To translate the app from English to German, we copy `en.json` and rename it to `de.json`. We keep the keys but change the values to our German translation. 

### Edit the app.dart file

Open the `irmamobile/lib/app.dart` file, you will find a section like this.

```dart
static List<Locale> defaultSupportedLocales() {
    return const [
      Locale('en', 'US'),
      Locale('nl', 'NL'),
    ];
  }
```

Add your language below the existing ones. 

*Example:* to add german, we add:

```dart
static List<Locale> defaultSupportedLocales() {
    return const [
      Locale('en', 'US'),
      Locale('nl', 'NL'),
      Locale('de', 'DE'),
    ];
  }
```

### Add translations to the scheme files

In the `pbdf-schememanager` you find files that describe the cards that people can load into IRMA. The files are placed in different folders, depending on who issues the card and what information the card contains. The relevant files are all called `description.xml`. 

The `description.xml` files contain *all translations* in corresponding tags. E.g., dutch texts are included in `<nl></nl>` tags and english texts are included in `<en></en>` tags. Add tags for the new language to all `description.xml` files and add your translation between these tags. 

*Example*: To translate the app to German, we automatically add a german tag-pair after all Dutch tag-pairs for all files in `pbdf-schememanager`. (For instance, in the `pbdf-schememanager` folder, we use regular expressions to replace `^(.*)(<nl>.*?</nl> *\n)` with  `$1$2$1<de></de>\n`). We then add the translations to all those german tag-pairs.

Snippet of `/pbdf-schememanager/gemeente/Issues/address/description.xml` before the addition:

```
		<en>Personal</en>
		<nl>Persoonlijk</nl>
```

Snippet after the addition:

```
		<en>Personal</en>
		<nl>Persoonlijk</nl>
		<de>Persönlich</de>
```


### Create pull requests

Once you have completed the translations, create pull requests for the changes in the [irmamobile](https://github.com/privacybydesign/irmamobile) repository and for the changes in the [pbdf-schememanager](https://github.com/privacybydesign/pbdf-schememanager) repository.


