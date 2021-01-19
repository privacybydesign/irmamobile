String irmaConfigurationEventJson = r"""
{
  "IrmaConfiguration": {
    "SchemeManagers": {
      "irma-demo": {
        "ID": "irma-demo",
        "Name": {
          "en": "Irma Demo",
          "nl": "Irma Demo"
        },
        "URL": "https://privacybydesign.foundation/schememanager/irma-demo",
        "Contact": "",
        "Demo": true,
        "Description": {
          "en": "Demo credentials within the IRMA domain",
          "nl": "Demo IRMA-credentials"
        },
        "MinimumAppVersion": {
          "Android": 0,
          "IOS": 0
        },
        "KeyshareServer": "",
        "KeyshareWebsite": "",
        "KeyshareAttribute": "",
        "TimestampServer": "https://keyshare.privacybydesign.foundation/atumd/",
        "XMLVersion": 7,
        "XMLName": {
          "Space": "",
          "Local": "SchemeManager"
        },
        "Status": "Valid",
        "Valid": true,
        "Timestamp": 1574169344
      },
      "pbdf": {
        "ID": "pbdf",
        "Name": {
          "en": "Privacy by Design Foundation",
          "nl": "Stichting Privacy by Design"
        },
        "URL": "https://localhost",
        "Contact": "",
        "Demo": false,
        "Description": {
          "en": "The Privacy by Design Foundation develops the IRMA app and the IRMA infrastructure, and issues basic attributes for free",
          "nl": "De stichting Privacy by Design ontwikkelt de IRMA app en de IRMA infrastructuur, en geeft gratis een set basisattributen uit"
        },
        "MinimumAppVersion": {
          "Android": 49,
          "IOS": 33
        },
        "KeyshareServer": "https://keyshare.privacybydesign.foundation/tomcat/irma_keyshare_server/api/v1",
        "KeyshareWebsite": "https://privacybydesign.foundation/mijnirma/",
        "KeyshareAttribute": "pbdf.pbdf.mijnirma.email",
        "TimestampServer": "https://keyshare.privacybydesign.foundation/atumd/",
        "XMLVersion": 7,
        "XMLName": {
          "Space": "",
          "Local": "SchemeManager"
        },
        "Status": "Valid",
        "Valid": true,
        "Timestamp": 1574921350
      }
    },
    "Issuers": {
      "irma-demo.DemoDuo": {
        "ID": "DemoDuo",
        "Name": {
          "en": "DemoDUO",
          "nl": "DemoDUO"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "Een demoDUO adres",
        "ContactEMail": "demoduo@example.com",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.IRMATube": {
        "ID": "IRMATube",
        "Name": {
          "en": "IRMATube",
          "nl": "IRMATube"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "Radboud Universiteit Nijmegen\nComeniuslaan 4\n6525 HP Nijmegen",
        "ContactEMail": "info@irmatube.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.MijnOverheid": {
        "ID": "MijnOverheid",
        "Name": {
          "en": "DemoVerheid.nl",
          "nl": "DemoVerheid.nl"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "Een demo-overheid",
        "ContactEMail": "demoverheid@example.com",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.RU": {
        "ID": "RU",
        "Name": {
          "en": "Demo University",
          "nl": "Demo Universiteit"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "",
        "ContactEMail": "",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.TWIpilot": {
        "ID": "TWIpilot",
        "Name": {
          "en": "Demo TWI Pilot",
          "nl": "Demo TWI Pilot"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://minszw.nl/",
        "ContactEMail": "christoph@ovrhd.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.alliander": {
        "ID": "alliander",
        "Name": {
          "en": "Demo Alliander",
          "nl": "Demo Alliander"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://www.alliander.com",
        "ContactEMail": "info@alliander.com",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.amsterdam": {
        "ID": "amsterdam",
        "Name": {
          "en": "Demo Municipality of Amsterdam",
          "nl": "Demo Gemeente Amsterdam"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://amsterdam.nl",
        "ContactEMail": "info@amsterdam.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.asito": {
        "ID": "asito",
        "Name": {
          "en": "Demo Asito",
          "nl": "Demo Asito"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://asito.nl",
        "ContactEMail": "",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.belastingdienst": {
        "ID": "belastingdienst",
        "Name": {
          "en": "Demo Belastingdienst",
          "nl": "Demo Belastingdienst"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://example.org",
        "ContactEMail": "example@example.org",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.chipsoft": {
        "ID": "chipsoft",
        "Name": {
          "en": "Demo ChipSoft",
          "nl": "Demo ChipSoft"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://example.org",
        "ContactEMail": "example@example.org",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.enschede": {
        "ID": "enschede",
        "Name": {
          "en": "Demo Gemeente Enschede",
          "nl": "Demo Gemeente Enschede"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://enschede.nl/",
        "ContactEMail": "k.masselink@enschede.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.forus": {
        "ID": "forus",
        "Name": {
          "en": "Forus - demo",
          "nl": "Forus - demo"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "Stichting Forus\nhttps://www.forus.io/",
        "ContactEMail": "info@forus.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.gebiedonline": {
        "ID": "gebiedonline",
        "Name": {
          "en": "Demo Gebiedonline",
          "nl": "Demo Gebiedonline"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://gebiedonline.nl/",
        "ContactEMail": "info@gebiedonline.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.gemeente": {
        "ID": "gemeente",
        "Name": {
          "en": "Demo Municipality",
          "nl": "Demo Gemeente"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://example.org",
        "ContactEMail": "example@example.org",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.gemeenten": {
        "ID": "gemeenten",
        "Name": {
          "en": "Demo Municipalities",
          "nl": "Demo Gemeenten"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://example.org",
        "ContactEMail": "example@example.org",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.haarlem": {
        "ID": "haarlem",
        "Name": {
          "en": "Municipality Haarlem",
          "nl": "Gemeente Haarlem"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://haarlem.nl/",
        "ContactEMail": "info@haarlem.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.ideal": {
        "ID": "ideal",
        "Name": {
          "en": "Demo iDeal",
          "nl": "Demo iDeal"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "",
        "ContactEMail": "",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.idin": {
        "ID": "idin",
        "Name": {
          "en": "Demo iDIN",
          "nl": "Demo iDIN"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "",
        "ContactEMail": "",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.irmages": {
        "ID": "irmages",
        "Name": {
          "en": "Irmages",
          "nl": "Irmages"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "Test",
        "ContactEMail": "test@test.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.ivido": {
        "ID": "ivido",
        "Name": {
          "en": "Demo Ivido",
          "nl": "Demo Ivido"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://ivido.nl",
        "ContactEMail": "info@ivido.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.kvk": {
        "ID": "kvk",
        "Name": {
          "en": "Demo Netherlands Chamber of Commerce",
          "nl": "Demo Kamer van Koophandel"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://www.kvk.nl",
        "ContactEMail": "info@example.com",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.maas": {
        "ID": "maas",
        "Name": {
          "en": "Demo MaaS",
          "nl": "Demo Maas"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "http://www.acceptinstitute.eu/",
        "ContactEMail": "",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.nijmegen": {
        "ID": "nijmegen",
        "Name": {
          "en": "Demo Gemeente Nijmegen",
          "nl": "Demo Gemeente Nijmegen"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://example.org",
        "ContactEMail": "example@example.org",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.nuts": {
        "ID": "nuts",
        "Name": {
          "en": "Demo Nuts",
          "nl": "Demo Nuts"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://nuts.nl",
        "ContactEMail": "info@nuts.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.rdw": {
        "ID": "rdw",
        "Name": {
          "en": "Demo RDW",
          "nl": "Demo RDW"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "",
        "ContactEMail": "",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.surf": {
        "ID": "surf",
        "Name": {
          "en": "Demo SURF",
          "nl": "Demo SURF"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://surfnet.nl",
        "ContactEMail": "info@surfnet.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.suwinet": {
        "ID": "suwinet",
        "Name": {
          "en": "Demo Suwinet",
          "nl": "Demo Suwinet"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://example.org",
        "ContactEMail": "example@example.org",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.vgz": {
        "ID": "vgz",
        "Name": {
          "en": "Demo VGZ",
          "nl": "Demo VGZ"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://www.vgz.nl",
        "ContactEMail": "digitalcooperation@vgz.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.vngrealisatie": {
        "ID": "vngrealisatie",
        "Name": {
          "en": "Demo VNG Realisatie",
          "nl": "Demo VNG Realisatie"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://commonground.pleio.nl/",
        "ContactEMail": "realisatie@vng.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.vzvz": {
        "ID": "vzvz",
        "Name": {
          "en": "Demo VZVZ",
          "nl": "Demo VZVZ"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://www.vzvz.nl",
        "ContactEMail": "support@vzvz.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "irma-demo.wigo4it": {
        "ID": "wigo4it",
        "Name": {
          "en": "Demo WIGO4IT",
          "nl": "Demo WIGO4IT"
        },
        "SchemeManagerID": "irma-demo",
        "ContactAddress": "https://wigo4it.nl/",
        "ContactEMail": "sjef.van.leeuwen@wigo4it.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "pbdf.chipsoft": {
        "ID": "chipsoft",
        "Name": {
          "en": "ChipSoft",
          "nl": "ChipSoft"
        },
        "SchemeManagerID": "pbdf",
        "ContactAddress": "https://www.chipsoft.nl",
        "ContactEMail": "eerstelijn@chipsoft.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "pbdf.gebiedonline": {
        "ID": "gebiedonline",
        "Name": {
          "en": "Gebiedonline",
          "nl": "Gebiedonline"
        },
        "SchemeManagerID": "pbdf",
        "ContactAddress": "https://gebiedonline.nl/",
        "ContactEMail": "info@gebiedonline.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "pbdf.gemeente": {
        "ID": "gemeente",
        "Name": {
          "en": "Your Municipality",
          "nl": "Uw Gemeente"
        },
        "SchemeManagerID": "pbdf",
        "ContactAddress": "https://www.nijmegen.nl",
        "ContactEMail": "b.withaar@nijmegen.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "pbdf.nijmegen": {
        "ID": "nijmegen",
        "Name": {
          "en": "Gemeente Nijmegen",
          "nl": "Gemeente Nijmegen"
        },
        "SchemeManagerID": "pbdf",
        "ContactAddress": "https://www.nijmegen.nl",
        "ContactEMail": "gemeente@nijmegen.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "pbdf.nuts": {
        "ID": "nuts",
        "Name": {
          "en": "Nuts",
          "nl": "Nuts"
        },
        "SchemeManagerID": "pbdf",
        "ContactAddress": "https://nuts.nl",
        "ContactEMail": "info@nuts.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "pbdf.pbdf": {
        "ID": "pbdf",
        "Name": {
          "en": "Privacy by Design Foundation",
          "nl": "Stichting Privacy by Design"
        },
        "SchemeManagerID": "pbdf",
        "ContactAddress": "",
        "ContactEMail": "info@privacybydesign.foundation",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "pbdf.sidn-pbdf": {
        "ID": "sidn-pbdf",
        "Name": {
          "en": "Privacy by Design Foundation via SIDN",
          "nl": "Stichting Privacy by Design via SIDN"
        },
        "SchemeManagerID": "pbdf",
        "ContactAddress": "https://www.sidn.nl",
        "ContactEMail": "support@sidn.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "pbdf.surf": {
        "ID": "surf",
        "Name": {
          "en": "SURF",
          "nl": "SURF"
        },
        "SchemeManagerID": "pbdf",
        "ContactAddress": "https://surfnet.nl",
        "ContactEMail": "info@surfnet.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      },
      "pbdf.vgz": {
        "ID": "vgz",
        "Name": {
          "en": "VGZ",
          "nl": "VGZ"
        },
        "SchemeManagerID": "pbdf",
        "ContactAddress": "https://www.vgz.nl",
        "ContactEMail": "digitalcooperation@vgz.nl",
        "DeprecatedSince": -62135596800,
        "XMLVersion": 4,
        "Valid": false
      }
    },
    "CredentialTypes": {
      "irma-demo.DemoDuo.demodiploma": {
        "ID": "demodiploma",
        "Name": {
          "en": "DemoDiploma",
          "nl": "DemoDiploma"
        },
        "IssuerID": "DemoDuo",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Data extracted from your diploma provided by DUO",
          "nl": "Gegevens uit uw diploma, verkregen via DUO"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "demouitgifte.en",
          "nl": "demouitgifte.nl"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.IRMATube.member": {
        "ID": "member",
        "Name": {
          "en": "Member",
          "nl": "Member"
        },
        "IssuerID": "IRMATube",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Your IRMATube membership.",
          "nl": "Uw IRMATube lidmaatschapsattributen"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.IRMATube.member.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.IRMATube.member.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.MijnOverheid.address": {
        "ID": "address",
        "Name": {
          "en": "Address",
          "nl": "Adres"
        },
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Address description issued by MijnOverheid based on GBA data",
          "nl": "Adres uitgegeven door MijnOverheid gebaseerd op GBA-gegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.MijnOverheid.address.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.MijnOverheid.address.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.MijnOverheid.ageHigher": {
        "ID": "ageHigher",
        "Name": {
          "en": "Senior Age limits",
          "nl": "Senior-leeftijdslimieten"
        },
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your senior age limits issued by MijnOverheid based on GBA data",
          "nl": "Uw senior-leeftijdslimieten uitgegeven door MijnOverheid gebaseeerd op GBA-data"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.MijnOverheid.ageHigher.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.MijnOverheid.ageHigher.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.MijnOverheid.ageLower": {
        "ID": "ageLower",
        "Name": {
          "en": "Lower Age limits",
          "nl": "Junior-leeftijdslimieten"
        },
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": ">Your junior age limits issued by MijnOverheid based on GBA data",
          "nl": "Uw junior-leeftijdslimieten uitgegeven door MijnOverheid gebaseeerd op GBA-data"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.MijnOverheid.ageLower.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.MijnOverheid.ageLower.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.MijnOverheid.birthCertificate": {
        "ID": "birthCertificate",
        "Name": {
          "en": "Birth Certificate",
          "nl": "geboorteakte"
        },
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your birth certificate",
          "nl": "Uw geboorteakte"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.MijnOverheid.birthCertificate.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.MijnOverheid.birthCertificate.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.MijnOverheid.drivinglicense": {
        "ID": "drivinglicense",
        "Name": {
          "en": "Demo Driving license",
          "nl": "Demo Rijbewijs"
        },
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Demo Driving license",
          "nl": "Demo Rijbewijs"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.MijnOverheid.drivinglicense.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.MijnOverheid.drivinglicense.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.MijnOverheid.fullName": {
        "ID": "fullName",
        "Name": {
          "en": "Name",
          "nl": "Naam"
        },
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your full name, as it is known to the government",
          "nl": "Uw volledige naam, zoals bekend bij de overheid"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.MijnOverheid.fullName.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.MijnOverheid.fullName.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.MijnOverheid.idDocument": {
        "ID": "idDocument",
        "Name": {
          "en": "ID Document",
          "nl": "Identiteitsbewijs"
        },
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "An identity document issued by the government.",
          "nl": "Een identiteitsbewijs uitgegeven door de overheid."
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.MijnOverheid.idDocument.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.MijnOverheid.idDocument.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.MijnOverheid.root": {
        "ID": "root",
        "Name": {
          "en": "Root",
          "nl": "Root"
        },
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Root credential issued by MijnOverheid.nl",
          "nl": "Root-credential uitgegeven door MijnOverheid.nl"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.MijnOverheid.root.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.MijnOverheid.root.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.RU.idinData": {
        "ID": "idinData",
        "Name": {
          "en": "iDIN data",
          "nl": ""
        },
        "IssuerID": "RU",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "iDIN personal data, issued by the Radboud University Nijmegen.",
          "nl": ""
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.RU.idinData.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.RU.idinData.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.RU.studentCard": {
        "ID": "studentCard",
        "Name": {
          "en": "Student Card",
          "nl": "Studentenkaart"
        },
        "IssuerID": "RU",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Student Card issued by the Radboud University Nijmegen",
          "nl": "Studentenkaart uitgegeven door de Radboud Universiteit Nijmegen"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.RU.studentCard.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.RU.studentCard.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.TWIpilot.TWIattributes": {
        "ID": "TWIattributes",
        "Name": {
          "en": "Demo TWIpilot attributen",
          "nl": "Demo TWIpilot attributes"
        },
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Attributes for TWi Pilots",
          "nl": "Attributen voor Pilots van TWI"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.TWIpilot.TWIattributes.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.TWIpilot.TWIattributes.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.alliander.connection": {
        "ID": "connection",
        "Name": {
          "en": "Demo Energy connection",
          "nl": "Demo Energieaansluiting"
        },
        "IssuerID": "alliander",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Identification numbers (EAN) for your electricity and gas connection. See https://www.eancodeboek.nl/",
          "nl": "Identificatienummers (EAN) voor uw electriciteits- en gasaansluiting. Zie https://www.eancodeboek.nl/"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.alliander.connection.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.alliander.connection.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.amsterdam.openStadBallot": {
        "ID": "openStadBallot",
        "Name": {
          "en": "Demo OpenStad ballot",
          "nl": "Demo OpenStad stembiljet"
        },
        "IssuerID": "amsterdam",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your right to vote with OpenStad supplied by Gemeente Amsterdam",
          "nl": "Uw recht om te stemmen met OpenStad uitgegeven door Gemeente Amsterdam"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.amsterdam.openStadBallot.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.amsterdam.openStadBallot.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.asito.loonstaat": {
        "ID": "loonstaat",
        "Name": {
          "en": "Demo Payroll Asito",
          "nl": "Demo Loonstaat Asito"
        },
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Payroll attributes for i4Sociaal Pilot Bijstand Aanvaarden Werk - Enschede",
          "nl": "Loonstaat attributen voor i4Sociaal Pilot Bijstand Aanvaarden Werk - Enschede"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.asito.loonstaat.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.asito.loonstaat.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.asito.paysheet": {
        "ID": "paysheet",
        "Name": {
          "en": "Demo Paysheet Asito",
          "nl": "Demo Loonstaat Asito"
        },
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Paysheet attributes for i4Sociaal Pilot Bijstand Aanvaarden Werk - Enschede",
          "nl": "Loonstaat attributen voor i4Sociaal Pilot Bijstand Aanvaarden Werk - Enschede"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.asito.paysheet.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.asito.paysheet.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.belastingdienst.verzamelinkomen": {
        "ID": "verzamelinkomen",
        "Name": {
          "en": "Demo Total year income",
          "nl": "Demo Verzamelinkomen"
        },
        "IssuerID": "belastingdienst",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Your total year income from the 3 tax 'boxes' and resulting income thresholds, as known by the Dutch tax office",
          "nl": "Het totaal van uw verzamelinkomen uit de 3 'boxen' en daaruit afgeleide inkomensgrenzen van de Belastingdienst"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.belastingdienst.verzamelinkomen.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.belastingdienst.verzamelinkomen.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.belastingdienst.verzamelinkomenhuishouden": {
        "ID": "verzamelinkomenhuishouden",
        "Name": {
          "en": "Demo Yearly income houshold",
          "nl": "Demo Verzamelinkomen huishouden"
        },
        "IssuerID": "belastingdienst",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "The total year income of your household, as known by the Dutch tax office",
          "nl": "Het verzamelinkomen van uw huishouden, zoals bekend bij de Belastingdienst"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.belastingdienst.verzamelinkomenhuishouden.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.belastingdienst.verzamelinkomenhuishouden.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.chipsoft.bsn": {
        "ID": "bsn",
        "Name": {
          "en": "Demo BSN from healthcare",
          "nl": "Demo BSN vanuit de zorg"
        },
        "IssuerID": "chipsoft",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your Dutch Citizen service number (BSN), from the Dutch population register, verified face to face",
          "nl": "Uw Burgerservicenummer (BSN), afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens, fysiek geverifieerd"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.chipsoft.bsn.html",
          "nl": "https://privacybydesign.foundation/attribute-index/en/irma-demo.chipsoft.bsn.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.enschede.bijstandsgerechtigd": {
        "ID": "bijstandsgerechtigd",
        "Name": {
          "en": "Demo Bijstand - Aanvaarden Werk",
          "nl": "Demo Bijstand - Aanvaarden Werk"
        },
        "IssuerID": "enschede",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Attributen voor Pilot Bijstand Aanvaarden Werk",
          "nl": "Attributen voor Pilot Bijstand Aanvaarden Werk"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.enschede.bijstandsgerechtigd.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.enschede.bijstandsgerechtigd.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.forus.demoKindpakket": {
        "ID": "demoKindpakket",
        "Name": {
          "en": "Demo kindpakket",
          "nl": "Demo kindpakket"
        },
        "IssuerID": "forus",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Demo kindpakket",
          "nl": "Demo kindpakket"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.forus.demoKindpakket.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.forus.demoKindpakket.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.gebiedonline.locality": {
        "ID": "locality",
        "Name": {
          "en": "Demo Gebiedonline",
          "nl": "Demo Gebiedonline"
        },
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Gebiedonline Locality",
          "nl": "Gebiedonline buurt en plaats"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.gebiedonline.locality.html",
          "nl": "https://privacybydesign.foundation/attribute-index/en/irma-demo.gebiedonline.locality.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.gebiedonline.locality2": {
        "ID": "locality2",
        "Name": {
          "en": "Demo Gebiedonline",
          "nl": "Demo Gebiedonline"
        },
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Gebiedonline Locality",
          "nl": "Gebiedonline buurt en plaats"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.gebiedonline.locality2.html",
          "nl": "https://privacybydesign.foundation/attribute-index/en/irma-demo.gebiedonline.locality2.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.gebiedonline.stakeholder": {
        "ID": "stakeholder",
        "Name": {
          "en": "Demo Gebiedonline",
          "nl": "Demo Gebiedonline"
        },
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "User of Gebiedonline platform",
          "nl": "Gebruiker van Gebiedonline platform"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.gebiedonline.stakeholder.html",
          "nl": "https://privacybydesign.foundation/attribute-index/en/irma-demo.gebiedonline.stakeholder.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.gemeente.address": {
        "ID": "address",
        "Name": {
          "en": "Demo Address",
          "nl": "Demo Adres"
        },
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your address, from the Dutch population register",
          "nl": "Uw adres, afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.gemeenten.address.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.gemeenten.address.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.gemeente.personalData": {
        "ID": "personalData",
        "Name": {
          "en": "Demo Personal data",
          "nl": "Demo Persoonsgegevens"
        },
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your personal data, from the Dutch population register",
          "nl": "Uw persoonsgegevens, afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.gemeenten.personalData.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.gemeenten.personalData.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.gemeenten.address": {
        "ID": "address",
        "Name": {
          "en": "Demo Address",
          "nl": "Demo Adres"
        },
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your address, from the Dutch population register",
          "nl": "Uw adres, afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.gemeenten.address.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.gemeenten.address.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.gemeenten.personalData": {
        "ID": "personalData",
        "Name": {
          "en": "Demo Personal data",
          "nl": "Demo Persoonsgegevens"
        },
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your personal data, from the Dutch population register",
          "nl": "Uw persoonsgegevens, afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.gemeenten.personalData.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.gemeenten.personalData.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.haarlem.medewerker": {
        "ID": "medewerker",
        "Name": {
          "en": "Demo Employee",
          "nl": "Demo Medewerker"
        },
        "IssuerID": "haarlem",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Attributes for Haarlem employees",
          "nl": "Attributen werknemers van Haarlem"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.haarlem.medewerker.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.haarlem.medewerker.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.ideal.ideal": {
        "ID": "ideal",
        "Name": {
          "en": "iDeal demo",
          "nl": "iDeal demo"
        },
        "IssuerID": "ideal",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Your personal data, provided by your bank, obtained through iDeal",
          "nl": "Uw identiteitsgegevens volgens uw bank, verkregen met iDeal."
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.ideal.ideal.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.ideal.ideal.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.idin.ageLimits": {
        "ID": "ageLimits",
        "Name": {
          "en": "Demo Age limits",
          "nl": "Demo Leeftijdslimieten"
        },
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your age limits, derived from your birthdate from the iDIN bank credential.",
          "nl": "Uw leeftijdsgrenzen, afgeleid uit uw geboortedatum afkomstig uit het iDIN bank credential."
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.idin.ageLimits.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.idin.ageLimits.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.idin.idin": {
        "ID": "idin",
        "Name": {
          "en": "iDIN demo",
          "nl": "iDIN demo"
        },
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your personal data, provided by your bank, obtained through iDIN",
          "nl": "Uw identiteitsgegevens volgens uw bank, verkregen met iDIN."
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.idin.idin.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.idin.idin.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.irmages.photos": {
        "ID": "photos",
        "Name": {
          "en": "Photos",
          "nl": "Pasfoto's"
        },
        "IssuerID": "irmages",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your photos from your passport.",
          "nl": "De foto's uit uw paspoort."
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.irmages.photos.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.irmages.photos.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.ivido.login": {
        "ID": "login",
        "Name": {
          "en": "Demo Ivido Login",
          "nl": "Demo Ivido Login"
        },
        "IssuerID": "ivido",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Attributen benodigd voor het inloggen bij Ivido",
          "nl": "Attributes required for logging in at Ivido"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.ivido.login.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.ivido.login.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.kvk.official": {
        "ID": "official",
        "Name": {
          "en": "Demo Official of a legal entity",
          "nl": "Demo Functionaris voor een rechtspersoon"
        },
        "IssuerID": "kvk",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "The personal information of an official of a legal entity",
          "nl": "The persoonlijke informatie van een functionaris voor een rechtspersoon"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.kvk.official.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.kvk.official.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.maas.maasid": {
        "ID": "maasid",
        "Name": {
          "en": "Demo MaaS ID",
          "nl": "Demo MaaS ID"
        },
        "IssuerID": "maas",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Demo MaaS ID",
          "nl": "Demo MaaS ID"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.maas.maasid.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.maas.maasid.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.nijmegen.address": {
        "ID": "address",
        "Name": {
          "en": "Demo Address",
          "nl": "Demo Adres"
        },
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your address, from the Dutch population register",
          "nl": "Uw adres, afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.nijmegen.address.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.nijmegen.address.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.nijmegen.ageLimits": {
        "ID": "ageLimits",
        "Name": {
          "en": "Demo Age limits",
          "nl": "Demo Leeftijdslimieten"
        },
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your age limits, derived from your birthdate from the Dutch population register",
          "nl": "Uw leeftijdsgrenzen, afgeleid uit uw geboortedatum afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.nijmegen.ageLimits.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.nijmegen.ageLimits.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.nijmegen.bsn": {
        "ID": "bsn",
        "Name": {
          "en": "Demo BSN",
          "nl": "Demo BSN"
        },
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your Dutch Citizen service number (BSN), from the Dutch population register",
          "nl": "Uw Burgerservicenummer (BSN), afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.nijmegen.bsn.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.nijmegen.bsn.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.nijmegen.personalData": {
        "ID": "personalData",
        "Name": {
          "en": "Demo Personal data",
          "nl": "Demo Persoonsgegevens"
        },
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your personal data, from the Dutch population register",
          "nl": "Uw persoonsgegevens, afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.nijmegen.personalData.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.nijmegen.personalData.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.nijmegen.travelDocument": {
        "ID": "travelDocument",
        "Name": {
          "en": "Demo Travel Document",
          "nl": "Demo Reisdocument"
        },
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Your Dutch passport or identity card, from the Dutch population register",
          "nl": "Uw Nederlandse paspoort of identiteitskaart, afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.nijmegen.travelDocument.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.nijmegen.travelDocument.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.nuts.agb": {
        "ID": "agb",
        "Name": {
          "en": "Demo Vektis agb by Nuts",
          "nl": "Demo Vektis agb by Nuts"
        },
        "IssuerID": "nuts",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Vektis agb attributes issued by Nuts.",
          "nl": "Vektis agb attributen uitgegeven door Nuts."
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.nuts.agb.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.nuts.agb.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.rdw.vrn": {
        "ID": "vrn",
        "Name": {
          "en": "vehicle registration demo",
          "nl": "kentekennummer demo"
        },
        "IssuerID": "rdw",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Your vehicle registration number.",
          "nl": "Uw kentekennummer"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.rdw.vrn.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.rdw.vrn.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.surf.surfdrive": {
        "ID": "surfdrive",
        "Name": {
          "en": "Demo SURFdrive license",
          "nl": "Demo SURFdrive licentie"
        },
        "IssuerID": "surf",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Your SURFdrive licence, for logging in at SURFdrive",
          "nl": "Uw SURFdrive licentie, waarmee u in kunt loggen op SURFdrive"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.surf.surfdrive.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.surf.surfdrive.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.suwinet.income": {
        "ID": "income",
        "Name": {
          "en": "Demo Suwinet Income",
          "nl": "Demo Suwinet Inkomensgegevens"
        },
        "IssuerID": "suwinet",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Income according to Suwinet",
          "nl": "Inkomen volgens Suwinet"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.suwinet.income.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.suwinet.income.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.vgz.machtiging": {
        "ID": "machtiging",
        "Name": {
          "en": "Demo Mandate",
          "nl": "Demo Machtiging"
        },
        "IssuerID": "vgz",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "With this mandate you can submit claims to VGZ on behalf of the person who mandated you",
          "nl": "Met deze machtiging kunt u declaraties indienen bij VGZ namens de verzekerde die u deze machtiging gegeven heeft"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.vgz.machtiging.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.vgz.machtiging.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.vngrealisatie.fieldlabparticipant": {
        "ID": "fieldlabparticipant",
        "Name": {
          "en": "Demo Fieldlab Participant",
          "nl": "Demo Fieldlabdeelnemer"
        },
        "IssuerID": "vngrealisatie",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Attributes for participating in a Common Ground fieldlab.",
          "nl": "Attributen voor deelname aan een Common Ground fieldlab."
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.vngrealisatie.fieldlabparticipant.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.vngrealisatie.fieldlabparticipant.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.vzvz.healthcareidentity": {
        "ID": "healthcareidentity",
        "Name": {
          "en": "Demo healthcare identity",
          "nl": "Demo zorgidentiteit"
        },
        "IssuerID": "vzvz",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your Dutch healthcare identity",
          "nl": "Uw zorgidentiteit"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.vzvz.healthcareidentity.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.vzvz.healthcareidentity.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "irma-demo.wigo4it.stadspas": {
        "ID": "stadspas",
        "Name": {
          "en": "Demo City Pass",
          "nl": "Demo Stadspas"
        },
        "IssuerID": "wigo4it",
        "SchemeManagerID": "irma-demo",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Attributes for citizen city passes",
          "nl": "Attributen voor stadspassen"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/attribute-index/en/irma-demo.wigo4it.stadspas.html",
          "nl": "https://privacybydesign.foundation/attribute-index/nl/irma-demo.wigo4it.stadspas.html"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.chipsoft.bsn": {
        "ID": "bsn",
        "Name": {
          "en": "BSN from healthcare",
          "nl": "BSN vanuit de zorg"
        },
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your Dutch Citizen service number (BSN), from the Dutch population register, verified face to face",
          "nl": "Uw Burgerservicenummer (BSN), afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens, fysiek geverifieerd"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": null,
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.chipsoft.testbsn": {
        "ID": "testbsn",
        "Name": {
          "en": "Test BSN from healthcare",
          "nl": "Test BSN vanuit de zorg"
        },
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Test BSN from healthcare",
          "nl": "Test BSN vanuit de zorg"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": null,
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.gebiedonline.livingarea": {
        "ID": "livingarea",
        "Name": {
          "en": "Living area",
          "nl": "Woongebied"
        },
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "The area where I live",
          "nl": "Het gebied waar ik woon"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://gebiedonline.nl/irma-uitleg",
          "nl": "https://gebiedonline.nl/irma-uitleg"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.gebiedonline.useridentification": {
        "ID": "useridentification",
        "Name": {
          "en": "User identification",
          "nl": "Gebruikersidentificatie"
        },
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "My identification for Gebiedonline community websites",
          "nl": "Mijn identificatie voor Gebiedonline community websites"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://gebiedonline.nl/irma-uitleg",
          "nl": "https://gebiedonline.nl/irma-uitleg"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.gebiedonline.workingarea": {
        "ID": "workingarea",
        "Name": {
          "en": "Working area",
          "nl": "Werkgebied"
        },
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "The area where I work",
          "nl": "Het gebied waar ik werk"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://gebiedonline.nl/irma-uitleg",
          "nl": "https://gebiedonline.nl/irma-uitleg"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.gemeente.address": {
        "ID": "address",
        "Name": {
          "en": "Address",
          "nl": "Adres"
        },
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your address, from the Dutch population register",
          "nl": "Uw adres, afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://services.nijmegen.nl/irma/gemeente/start",
          "nl": "https://services.nijmegen.nl/irma/gemeente/start"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.gemeente.personalData": {
        "ID": "personalData",
        "Name": {
          "en": "Citizen data",
          "nl": "Inwonersgegevens"
        },
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your personal data, from the Dutch population register",
          "nl": "Uw persoonsgegevens, afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://services.nijmegen.nl/irma/gemeente/start",
          "nl": "https://services.nijmegen.nl/irma/gemeente/start"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "#2f5597",
        "IsInCredentialStore": true,
        "Category": {
          "en": "",
          "nl": "Persoonsgegevens"
        },
        "FAQIntro": {
          "en": "",
          "nl": "Zet je officiële naam, adres, geboortedatum en BSN in IRMA met je DigiD. Met je officiële gegevens in IRMA, is online identificeren veilig en eenvoudig."
        },
        "FAQPurpose": {
          "en": "",
          "nl": "Met IRMA kun je deze persoonsgegevens gebruiken om jezelf online bekend te maken. Je kunt bijvoorbeeld bewijzen hoe oud je bent, of waar je woont zonder je naam prijs te geven."
        },
        "FAQContent": {
          "en": "",
          "nl": "Je haalt o.a. de volgende gegevens op bij je gemeente:\\n\\n• initialen\\n• achternaam\\n• geboortedatum\\n• leeftijd (ouder dan 12, 16, 18, 21 of 65)\\n• geslacht\\n• adres\\n• postcode\\n• plaats\\n• Burgerservicenummer (BSN)"
        },
        "FAQHowto": {
          "en": "",
          "nl": "Je haalt je gegevens op bij je gemeente in twee stappen:\\n\\n1. Log in met DigiD.\\n2. Bevestig de gegevens in IRMA.\\n\\nNu kun je je met IRMA online bekend maken.\\nLet op: je gegevens in IRMA zijn geldig tot de aangegeven datum. Daarna moet je ze vernieuwen."
        },
        "Valid": false
      },
      "pbdf.nijmegen.address": {
        "ID": "address",
        "Name": {
          "en": "Address",
          "nl": "Adres"
        },
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your address, from the Dutch population register",
          "nl": "Uw adres, afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://services.nijmegen.nl/irma/issue/start",
          "nl": "https://services.nijmegen.nl/irma/issue/start"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.nijmegen.ageLimits": {
        "ID": "ageLimits",
        "Name": {
          "en": "Age limits",
          "nl": "Leeftijdslimieten"
        },
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your age limits, derived from your birthdate from the Dutch population register",
          "nl": "Uw leeftijdsgrenzen, afgeleid uit uw geboortedatum afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://services.nijmegen.nl/irma/issue/start",
          "nl": "https://services.nijmegen.nl/irma/issue/start"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.nijmegen.bsn": {
        "ID": "bsn",
        "Name": {
          "en": "BSN",
          "nl": "BSN"
        },
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your Dutch Citizen service number (BSN), from the Dutch population register",
          "nl": "Uw Burgerservicenummer (BSN), afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://services.nijmegen.nl/irma/issue/start",
          "nl": "https://services.nijmegen.nl/irma/issue/start"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.nijmegen.personalData": {
        "ID": "personalData",
        "Name": {
          "en": "Personal data",
          "nl": "Persoonsgegevens"
        },
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your personal data, from the Dutch population register",
          "nl": "Uw persoonsgegevens, afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://services.nijmegen.nl/irma/issue/start",
          "nl": "https://services.nijmegen.nl/irma/issue/start"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.nijmegen.travelDocument": {
        "ID": "travelDocument",
        "Name": {
          "en": "Travel Document",
          "nl": "Reisdocument"
        },
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Your Dutch passport or identity card, from the Dutch population register",
          "nl": "Uw Nederlandse paspoort of identiteitskaart, afkomstig uit de Nederlandse Basisregistratie Persoonsgegevens"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://services.nijmegen.nl/irma/issue/start",
          "nl": "https://services.nijmegen.nl/irma/issue/start"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.nuts.agb": {
        "ID": "agb",
        "Name": {
          "en": "AGB",
          "nl": "AGB"
        },
        "IssuerID": "nuts",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "An AGB-code (in Dutch: Algemeen GegevensBeheer-code) is a Dutch national code system which uniquely identifies a care provider. Care providers are registered in a national database with this code. The database is maintained by Vektis",
          "nl": "Een Algemeen GegevensBeheer-code (kort: AGB-code) is een landelijke code waarmee een zorgaanbieder kan worden herkend. Met deze unieke code staan zorgaanbieders geregistreerd in een landelijke database. Dit systeem wordt beheerd door Vektis"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://irma-agb.nuts.nl/",
          "nl": "https://irma-agb.nuts.nl/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "#ff0000",
        "IsInCredentialStore": true,
        "Category": {
          "en": "",
          "nl": "Zorg"
        },
        "FAQIntro": {
          "en": "",
          "nl": "TODO"
        },
        "FAQPurpose": {
          "en": "",
          "nl": "TODO"
        },
        "FAQContent": {
          "en": "",
          "nl": "TODO"
        },
        "FAQHowto": {
          "en": "",
          "nl": "TODO"
        },
        "Valid": false
      },
      "pbdf.pbdf.ageLimits": {
        "ID": "ageLimits",
        "Name": {
          "en": "Age limits",
          "nl": "Leeftijdslimieten"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your age attributes, issued after revealing your birthdate, from your iDIN bank attributes",
          "nl": "Uw leeftijdsgrenzen zoals berekend uit uw geboortedatum, uit uw iDIN bank attributen"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/issuance/idin/",
          "nl": "https://privacybydesign.foundation/uitgifte/idin/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.pbdf.big": {
        "ID": "big",
        "Name": {
          "en": "BIG registration",
          "nl": "BIG-registratie"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "BIG attributes from the BIG registration",
          "nl": "BIG-attributen uit het BIG-register"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/issuance/big/",
          "nl": "https://privacybydesign.foundation/uitgifte/big/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.pbdf.diploma": {
        "ID": "diploma",
        "Name": {
          "en": "Diploma",
          "nl": "Diploma"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Data extracted from your diploma provided by DUO",
          "nl": "Gegevens uit uw diploma, verkregen via DUO"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/uitgifte/diploma/",
          "nl": "https://privacybydesign.foundation/uitgifte/diploma/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.pbdf.email": {
        "ID": "email",
        "Name": {
          "en": "Email address",
          "nl": "E-mailadres"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Your verified email address",
          "nl": "Uw geverifieerde e-mailadres"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/issuance/email/",
          "nl": "https://privacybydesign.foundation/uitgifte/email/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "#00b050",
        "IsInCredentialStore": true,
        "Category": {
          "en": "",
          "nl": "Persoonsgegevens"
        },
        "FAQIntro": {
          "en": "",
          "nl": "Voeg je e-mailadres(sen) toe aan IRMA. Met je e-mailadres in IRMA, laat je online zien dat jij bij dit e-mailadres hoort."
        },
        "FAQPurpose": {
          "en": "",
          "nl": "Met IRMA kun je laten zien dat dit e-mailadres echt van jou is. Je kunt bijvoorbeeld je e-mailadres gebruiken om in te loggen. Als je je e-mailadres uit IRMA gebruikt, weet de ander zeker dat jij bij dit e-mailadres hoort."
        },
        "FAQContent": {
          "en": "",
          "nl": "Je emailadres"
        },
        "FAQHowto": {
          "en": "",
          "nl": "Je voegt je e-mailadres(sen) toe in vier stappen:\\n\\n1. Vul je e-mailadres in.\\n 2. Open de bevestigingsmail met de bevestigingscode in je inbox.\\n 3. Vul de bevestigingscode in in IRMA.\\n 4. Je e-mailadres staat nu in IRMA.\\n\\nNu kun je je met IRMA online bekend maken.\\n\\nLet op: je gegevens in IRMA zijn geldig tot de aangegeven datum. Daarna moet je ze vernieuwen."
        },
        "Valid": false
      },
      "pbdf.pbdf.facebook": {
        "ID": "facebook",
        "Name": {
          "en": "Facebook",
          "nl": "Facebook"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Facebook attributes obtained using Facebook Connect",
          "nl": "Facebook-attributen verkregen via Facebook Connect"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/issuance/social/facebook/",
          "nl": "https://privacybydesign.foundation/uitgifte/social/facebook/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.pbdf.ideal": {
        "ID": "ideal",
        "Name": {
          "en": "iDEAL",
          "nl": "iDEAL"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Your personal data, provided by your bank, obtained through iDEAL",
          "nl": "Uw identiteitsgegevens volgens uw bank, verkregen met iDEAL"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/issuance/ideal-idin/",
          "nl": "https://privacybydesign.foundation/uitgifte/ideal-idin/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.pbdf.idin": {
        "ID": "idin",
        "Name": {
          "en": "iDIN",
          "nl": "iDIN"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your personal data, provided by your bank, obtained through iDIN",
          "nl": "Uw identiteitsgegevens volgens uw bank, verkregen met iDIN"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/issuance/ideal-idin/",
          "nl": "https://privacybydesign.foundation/uitgifte/ideal-idin/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "#00b0f0",
        "IsInCredentialStore": true,
        "Category": {
          "en": "",
          "nl": "Persoonsgegevens"
        },
        "FAQIntro": {
          "en": "",
          "nl": "Voeg je iDIN-gegevens toe aan IRMA."
        },
        "FAQPurpose": {
          "en": "",
          "nl": "Met IRMA kun je je iDIN-gegevens gebruiken om jezelf online bekend te maken. Je kunt bijvoorbeeld bewijzen hoe je heet zonder je adres prijs te geven."
        },
        "FAQContent": {
          "en": "",
          "nl": "Je haalt o.a. de volgende iDIN-gegevens op:\\n\\n• initialen\\n• achternaam\\n• geboortedatum\\n• geslacht\\n• adres\\n• postcode\\n• plaats"
        },
        "FAQHowto": {
          "en": "",
          "nl": "Je voegt je iDIN-gegevens toe in vijf stappen:\\n\\n1. Kies je bank. \\n2. Log in op de bankieren app van jouw bank.\\n3. Je ziet de gegevens die je van jouw bank in IRMA haalt.\\n4. Bevestig dat je deze gegevens in IRMA wilt halen.\\n5. Je iDIN-gegevens staan nu in IRMA.\\n\\nNu kun je je met IRMA online bekend maken. \\n\\nLet op: je gegevens in IRMA zijn geldig tot de aangegeven datum. Daarna moet je ze vernieuwen."
        },
        "Valid": false
      },
      "pbdf.pbdf.irmatube": {
        "ID": "irmatube",
        "Name": {
          "en": "IRMATube membership",
          "nl": "IRMATube lidmaatschap"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your IRMATube membership attributes",
          "nl": "Uw IRMATube lidmaatschapsattributen"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/demo-en/irmaTube/",
          "nl": "https://privacybydesign.foundation/demo/irmaTube/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.pbdf.linkedin": {
        "ID": "linkedin",
        "Name": {
          "en": "LinkedIn",
          "nl": "LinkedIn"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "LinkedIn attributes from your LinkedIn account",
          "nl": "LinkedIn attributen uit uw LinkedIn account"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/issuance/social/linkedin/",
          "nl": "https://privacybydesign.foundation/uitgifte/social/linkedin/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.pbdf.mijnirma": {
        "ID": "mijnirma",
        "Name": {
          "en": "MyIRMA",
          "nl": "MijnIRMA"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your MyIRMA attribute",
          "nl": "Uw MijnIRMA-attribuut"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": null,
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.pbdf.mobilenumber": {
        "ID": "mobilenumber",
        "Name": {
          "en": "Telephone number",
          "nl": "Telefoongegevens"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Your verified mobile phone number",
          "nl": "Uw geverifieerde mobiel telefoonnummer"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/issuance/phonenumber/",
          "nl": "https://privacybydesign.foundation/uitgifte/telefoonnummer/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "#00b050",
        "IsInCredentialStore": true,
        "Category": {
          "en": "",
          "nl": "Persoonsgegevens"
        },
        "FAQIntro": {
          "en": "",
          "nl": "Voeg je telefoonnummer(s) toe aan IRMA. Met je telefoonnummer in IRMA, laat je online zien dat jij bij dit telefoonnummer hoort."
        },
        "FAQPurpose": {
          "en": "",
          "nl": "Met IRMA kun je laten zien dat dit telefoonnummer echt van jou is. Je kunt bijvoorbeeld je telefoonnummer opgeven om teruggebeld te worden. Als je je telefoonnummer uit IRMA gebruikt, weet de ander zeker dat jij bij dit telefoonnummer hoort."
        },
        "FAQContent": {
          "en": "",
          "nl": "Je telefoonnummer"
        },
        "FAQHowto": {
          "en": "",
          "nl": "Je voegt je telefoonnummer toe in vier stappen:\\n\\n1. Vul je telefoonnummer in.\\n2. Open de sms met de bevestigingscode.\\n3. Vul de bevestigingscode in in IRMA.\\n4. Je telefoonnummer staat nu in IRMA.\\n\\nNu kun je je met IRMA online bekend maken.\\n\\nLet op: je gegevens in IRMA zijn geldig tot de aangegeven datum. Daarna moet je ze vernieuwen."
        },
        "Valid": false
      },
      "pbdf.pbdf.surfnet": {
        "ID": "surfnet",
        "Name": {
          "en": "Surfnet",
          "nl": "Surfnet"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your Surfnet attributes obtained through SURFconext",
          "nl": "Uw Surfnet-attributen, verkregen via SURFconext"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/issuance/surfnet/surfnet/",
          "nl": "https://privacybydesign.foundation/uitgifte/surfnet/surfnet/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.pbdf.surfnet-2": {
        "ID": "surfnet-2",
        "Name": {
          "en": "Surfnet",
          "nl": "Surfnet"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Your Surfnet attributes obtained through SURFconext",
          "nl": "Uw Surfnet-attributen, verkregen via SURFconext"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/issuance/surfnet/surfnet/",
          "nl": "https://privacybydesign.foundation/uitgifte/surfnet/surfnet/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "#ffc000",
        "IsInCredentialStore": true,
        "Category": {
          "en": "",
          "nl": "Onderwijs"
        },
        "FAQIntro": {
          "en": "",
          "nl": "TODO"
        },
        "FAQPurpose": {
          "en": "",
          "nl": "TODO"
        },
        "FAQContent": {
          "en": "",
          "nl": "TODO"
        },
        "FAQHowto": {
          "en": "",
          "nl": "TODO"
        },
        "Valid": false
      },
      "pbdf.pbdf.twitter": {
        "ID": "twitter",
        "Name": {
          "en": "Twitter",
          "nl": "Twitter"
        },
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Twitter attributes from your Twitter account",
          "nl": "Twitter attributen uit uw Twitter account"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://privacybydesign.foundation/issuance/social/twitter/",
          "nl": "https://privacybydesign.foundation/uitgifte/social/twitter/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.sidn-pbdf.irma": {
        "ID": "irma",
        "Name": {
          "en": "MyIRMA",
          "nl": "MijnIRMA"
        },
        "IssuerID": "sidn-pbdf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": true,
        "DisallowDelete": false,
        "Description": {
          "en": "Your MyIRMA attribute",
          "nl": "Uw MijnIRMA-attribuut"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": null,
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.surf.secureid": {
        "ID": "secureid",
        "Name": {
          "en": "SURFsecureID",
          "nl": "SURFsecureID"
        },
        "IssuerID": "surf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Your SURFsecureID 2nd factor",
          "nl": "Uw SURFsecureID tweede factor"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": {
          "en": "https://sa.surfconext.nl/registration/select-token/",
          "nl": "https://sa.surfconext.nl/registration/select-token/"
        },
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.surf.surfdrive": {
        "ID": "surfdrive",
        "Name": {
          "en": "SURFdrive license",
          "nl": "SURFdrive licentie"
        },
        "IssuerID": "surf",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "Your SURFdrive licence, for logging in at SURFdrive",
          "nl": "Uw SURFdrive licentie, waarmee u in kunt loggen op SURFdrive"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": null,
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      },
      "pbdf.vgz.machtiging": {
        "ID": "machtiging",
        "Name": {
          "en": "Mandate",
          "nl": "Machtiging"
        },
        "IssuerID": "vgz",
        "SchemeManagerID": "pbdf",
        "IsSingleton": false,
        "DisallowDelete": false,
        "Description": {
          "en": "With this mandate you can submit claims to VGZ on behalf of the person who mandated you",
          "nl": "Met deze machtiging kunt u declaraties indienen bij VGZ namens de verzekerde die u deze machtiging gegeven heeft"
        },
        "XMLVersion": 4,
        "XMLName": {
          "Space": "",
          "Local": "IssueSpecification"
        },
        "IssueURL": null,
        "DeprecatedSince": -62135596800,
        "BackgroundColor": "",
        "IsInCredentialStore": false,
        "Category": null,
        "FAQIntro": null,
        "FAQPurpose": null,
        "FAQContent": null,
        "FAQHowto": null,
        "Valid": false
      }
    },
    "AttributeTypes": {
      "irma-demo.DemoDuo.demodiploma.achieved": {
        "ID": "achieved",
        "Name": {
          "en": "Achieved in",
          "nl": "Behaald in"
        },
        "Description": {
          "en": "Month of achieving this diploma",
          "nl": "Maand waarin dit diploma behaald is"
        },
        "Index": 8,
        "CredentialTypeID": "demodiploma",
        "IssuerID": "DemoDuo",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.DemoDuo.demodiploma.city": {
        "ID": "city",
        "Name": {
          "en": "City",
          "nl": "Stad"
        },
        "Description": {
          "en": "The city of the institute where this degree has been achieved",
          "nl": "De stad van de instantie waar dit diploma behaald is"
        },
        "Index": 10,
        "CredentialTypeID": "demodiploma",
        "IssuerID": "DemoDuo",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.DemoDuo.demodiploma.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth from your diploma",
          "nl": "Uw geboortedatum uit uw diploma"
        },
        "Index": 3,
        "CredentialTypeID": "demodiploma",
        "IssuerID": "DemoDuo",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.DemoDuo.demodiploma.degree": {
        "ID": "degree",
        "Optional": "true",
        "Name": {
          "en": "Degree",
          "nl": "Opleiding"
        },
        "Description": {
          "en": "Type of education",
          "nl": "Soort opleiding"
        },
        "Index": 6,
        "CredentialTypeID": "demodiploma",
        "IssuerID": "DemoDuo",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.DemoDuo.demodiploma.education": {
        "ID": "education",
        "Name": {
          "en": "Education",
          "nl": "Opleiding"
        },
        "Description": {
          "en": "Completed education",
          "nl": "Voltooide opleiding"
        },
        "Index": 5,
        "CredentialTypeID": "demodiploma",
        "IssuerID": "DemoDuo",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.DemoDuo.demodiploma.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your family name from your diploma",
          "nl": "Uw achternaam uit uw diploma"
        },
        "Index": 2,
        "CredentialTypeID": "demodiploma",
        "IssuerID": "DemoDuo",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.DemoDuo.demodiploma.firstname": {
        "ID": "firstname",
        "Name": {
          "en": "First name",
          "nl": "Voornaam"
        },
        "Description": {
          "en": "Your first name from your diploma",
          "nl": "Uw voornaam uit uw diploma"
        },
        "Index": 0,
        "CredentialTypeID": "demodiploma",
        "IssuerID": "DemoDuo",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.DemoDuo.demodiploma.gender": {
        "ID": "gender",
        "Name": {
          "en": "Gender",
          "nl": "Geslacht"
        },
        "Description": {
          "en": "Your gender from your diploma",
          "nl": "Uw geslacht uit uw diploma"
        },
        "Index": 4,
        "CredentialTypeID": "demodiploma",
        "IssuerID": "DemoDuo",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.DemoDuo.demodiploma.institute": {
        "ID": "institute",
        "Name": {
          "en": "Institute",
          "nl": "Instituut"
        },
        "Description": {
          "en": "The institute where this degree has been achieved",
          "nl": "De instantie waar dit diploma behaald is"
        },
        "Index": 9,
        "CredentialTypeID": "demodiploma",
        "IssuerID": "DemoDuo",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.DemoDuo.demodiploma.prefix": {
        "ID": "prefix",
        "Optional": "true",
        "Name": {
          "en": "Prefix",
          "nl": "Tussenvoegsel"
        },
        "Description": {
          "en": "Your family name prefix from your diploma",
          "nl": "Uw tussenvoegsel uit uw diploma"
        },
        "Index": 1,
        "CredentialTypeID": "demodiploma",
        "IssuerID": "DemoDuo",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.DemoDuo.demodiploma.profile": {
        "ID": "profile",
        "Optional": "true",
        "Name": {
          "en": "Profile",
          "nl": "Profiel"
        },
        "Description": {
          "en": "Education profile",
          "nl": "Opleidingsprofiel"
        },
        "Index": 7,
        "CredentialTypeID": "demodiploma",
        "IssuerID": "DemoDuo",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.IRMATube.member.id": {
        "ID": "id",
        "Name": {
          "en": "id",
          "nl": "id"
        },
        "Description": {
          "en": "The membership id",
          "nl": "Uw lidmaatschapsnummer"
        },
        "Index": 1,
        "CredentialTypeID": "member",
        "IssuerID": "IRMATube",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.IRMATube.member.type": {
        "ID": "type",
        "Name": {
          "en": "type",
          "nl": "type"
        },
        "Description": {
          "en": "Your membership type",
          "nl": "Uw lidmaatschapstype"
        },
        "Index": 0,
        "CredentialTypeID": "member",
        "IssuerID": "IRMATube",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.address.city": {
        "ID": "city",
        "Name": {
          "en": "City",
          "nl": "Stad"
        },
        "Description": {
          "en": "The city you live in",
          "nl": "Uw woonplaats"
        },
        "Index": 1,
        "CredentialTypeID": "address",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.address.country": {
        "ID": "country",
        "Name": {
          "en": "Country",
          "nl": "Land"
        },
        "Description": {
          "en": "The country you live in",
          "nl": "Het land waarin u woont"
        },
        "Index": 0,
        "CredentialTypeID": "address",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.address.street": {
        "ID": "street",
        "Name": {
          "en": "Street",
          "nl": "Straat"
        },
        "Description": {
          "en": "Your street and house number",
          "nl": "Uw straat en huisnummer"
        },
        "Index": 2,
        "CredentialTypeID": "address",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.address.zipcode": {
        "ID": "zipcode",
        "Name": {
          "en": "ZIP code",
          "nl": "Postcode"
        },
        "Description": {
          "en": "Your ZIP code",
          "nl": "Uw postcode"
        },
        "Index": 3,
        "CredentialTypeID": "address",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.ageHigher.over50": {
        "ID": "over50",
        "Name": {
          "en": "Over 50",
          "nl": "Ouder dan 50"
        },
        "Description": {
          "en": "If you are over 50",
          "nl": "Of u ouder bent dan 50"
        },
        "Index": 0,
        "CredentialTypeID": "ageHigher",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.ageHigher.over60": {
        "ID": "over60",
        "Name": {
          "en": "Over 60",
          "nl": "Ouder dan 60"
        },
        "Description": {
          "en": "If you are over 60",
          "nl": ">Of u ouder bent dan 60"
        },
        "Index": 1,
        "CredentialTypeID": "ageHigher",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.ageHigher.over65": {
        "ID": "over65",
        "Name": {
          "en": "Over 65",
          "nl": "Ouder dan 65"
        },
        "Description": {
          "en": "If you are over 65",
          "nl": ">Of u ouder bent dan 65"
        },
        "Index": 2,
        "CredentialTypeID": "ageHigher",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.ageHigher.over75": {
        "ID": "over75",
        "Name": {
          "en": "Over 75",
          "nl": "Ouder dan 75"
        },
        "Description": {
          "en": "If you are over 75",
          "nl": ">Of u ouder bent dan 75"
        },
        "Index": 3,
        "CredentialTypeID": "ageHigher",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.ageLower.over12": {
        "ID": "over12",
        "Name": {
          "en": "Over 12",
          "nl": "Ouder dan 12"
        },
        "Description": {
          "en": "If you are over 12",
          "nl": "Of u ouder bent dan 12"
        },
        "Index": 0,
        "CredentialTypeID": "ageLower",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.ageLower.over16": {
        "ID": "over16",
        "Name": {
          "en": "Over 16",
          "nl": "Ouder dan 16"
        },
        "Description": {
          "en": "If you are over 16",
          "nl": "Of u ouder bent dan 16"
        },
        "Index": 1,
        "CredentialTypeID": "ageLower",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.ageLower.over18": {
        "ID": "over18",
        "Name": {
          "en": "Over 18",
          "nl": "Ouder dan 18"
        },
        "Description": {
          "en": "If you are over 18",
          "nl": "Of u ouder bent dan 18"
        },
        "Index": 2,
        "CredentialTypeID": "ageLower",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.ageLower.over21": {
        "ID": "over21",
        "Name": {
          "en": "Over 21",
          "nl": "Ouder dan 21"
        },
        "Description": {
          "en": "If you are over 21",
          "nl": "Of u ouder bent dan 21"
        },
        "Index": 3,
        "CredentialTypeID": "ageLower",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.birthCertificate.countryofbirth": {
        "ID": "countryofbirth",
        "Name": {
          "en": "Country of birth",
          "nl": "Geboorteland"
        },
        "Description": {
          "en": "Your birth country",
          "nl": "Land waar u geboren bent"
        },
        "Index": 2,
        "CredentialTypeID": "birthCertificate",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.birthCertificate.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your birth date",
          "nl": "Uw geboortedatum"
        },
        "Index": 0,
        "CredentialTypeID": "birthCertificate",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.birthCertificate.gender": {
        "ID": "gender",
        "Name": {
          "en": "Gender",
          "nl": "Geslacht"
        },
        "Description": {
          "en": "Your gender",
          "nl": "Uw geslacht"
        },
        "Index": 3,
        "CredentialTypeID": "birthCertificate",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.birthCertificate.placeofbirth": {
        "ID": "placeofbirth",
        "Name": {
          "en": "Place of birth",
          "nl": "Uw geboorteplaats"
        },
        "Description": {
          "en": "Your place of birth",
          "nl": "Uw geboorteplaats"
        },
        "Index": 1,
        "CredentialTypeID": "birthCertificate",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.drivinglicense.country": {
        "ID": "country",
        "Name": {
          "en": "country",
          "nl": "country"
        },
        "Description": {
          "en": "",
          "nl": ""
        },
        "Index": 5,
        "CredentialTypeID": "drivinglicense",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.drivinglicense.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "dateofbirth",
          "nl": "dateofbirth"
        },
        "Description": {
          "en": "",
          "nl": ""
        },
        "Index": 2,
        "CredentialTypeID": "drivinglicense",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.drivinglicense.expires": {
        "ID": "expires",
        "Name": {
          "en": "expires",
          "nl": "expires"
        },
        "Description": {
          "en": "",
          "nl": ""
        },
        "Index": 7,
        "CredentialTypeID": "drivinglicense",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.drivinglicense.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "familyname",
          "nl": "familyname"
        },
        "Description": {
          "en": "",
          "nl": ""
        },
        "Index": 1,
        "CredentialTypeID": "drivinglicense",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.drivinglicense.firstnames": {
        "ID": "firstnames",
        "Name": {
          "en": "firstnames",
          "nl": "firstnames"
        },
        "Description": {
          "en": "",
          "nl": ""
        },
        "Index": 0,
        "CredentialTypeID": "drivinglicense",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.drivinglicense.licensed": {
        "ID": "licensed",
        "Name": {
          "en": "licensed",
          "nl": "licensed"
        },
        "Description": {
          "en": "",
          "nl": ""
        },
        "Index": 4,
        "CredentialTypeID": "drivinglicense",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.drivinglicense.number": {
        "ID": "number",
        "Name": {
          "en": "number",
          "nl": "number"
        },
        "Description": {
          "en": "",
          "nl": ""
        },
        "Index": 6,
        "CredentialTypeID": "drivinglicense",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.drivinglicense.placeofbirth": {
        "ID": "placeofbirth",
        "Name": {
          "en": "placeofbirth",
          "nl": "placeofbirth"
        },
        "Description": {
          "en": "",
          "nl": ""
        },
        "Index": 3,
        "CredentialTypeID": "drivinglicense",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.fullName.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your family name",
          "nl": "Uw achternaam"
        },
        "Index": 2,
        "CredentialTypeID": "fullName",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.fullName.firstname": {
        "ID": "firstname",
        "Name": {
          "en": "First name",
          "nl": "Voornaam"
        },
        "Description": {
          "en": "Your first name",
          "nl": "Uw voornaam"
        },
        "Index": 1,
        "CredentialTypeID": "fullName",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.fullName.firstnames": {
        "ID": "firstnames",
        "Name": {
          "en": "First names",
          "nl": "Voornamen"
        },
        "Description": {
          "en": "All of your first names",
          "nl": "Al uw voornamen"
        },
        "Index": 0,
        "CredentialTypeID": "fullName",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.fullName.prefix": {
        "ID": "prefix",
        "Optional": "true",
        "Name": {
          "en": "Prefix",
          "nl": "Tussenvoegsel"
        },
        "Description": {
          "en": "Family name prefix",
          "nl": "Tussenvoegsel van uw achternaam"
        },
        "Index": 3,
        "CredentialTypeID": "fullName",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.idDocument.expires": {
        "ID": "expires",
        "Name": {
          "en": "Expires",
          "nl": "Verloopdatum"
        },
        "Description": {
          "en": "The expiry date of the document",
          "nl": "Verloopdatum van het identiteitsbewijs"
        },
        "Index": 2,
        "CredentialTypeID": "idDocument",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.idDocument.nationality": {
        "ID": "nationality",
        "Name": {
          "en": "Nationality",
          "nl": "Nationaliteit"
        },
        "Description": {
          "en": "The nationality of the owner",
          "nl": "Nationaliteit van de eigenaar"
        },
        "Index": 3,
        "CredentialTypeID": "idDocument",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.idDocument.number": {
        "ID": "number",
        "Name": {
          "en": "Number",
          "nl": "Nummer"
        },
        "Description": {
          "en": "The document number",
          "nl": "Documentnummer van het identiteitsbewijs"
        },
        "Index": 1,
        "CredentialTypeID": "idDocument",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.idDocument.type": {
        "ID": "type",
        "Name": {
          "en": "Type",
          "nl": "Type"
        },
        "Description": {
          "en": "The type of identity document",
          "nl": "Type van het identiteitsbewijs"
        },
        "Index": 0,
        "CredentialTypeID": "idDocument",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.MijnOverheid.root.BSN": {
        "ID": "BSN",
        "Name": {
          "en": "BSN",
          "nl": "BSN"
        },
        "Description": {
          "en": "Your BSN-number",
          "nl": "Uw BSN-nummer"
        },
        "Index": 0,
        "CredentialTypeID": "root",
        "IssuerID": "MijnOverheid",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.RU.idinData.address": {
        "ID": "address",
        "Name": {
          "en": "address",
          "nl": ""
        },
        "Description": {
          "en": "The address at which you live",
          "nl": ""
        },
        "Index": 4,
        "CredentialTypeID": "idinData",
        "IssuerID": "RU",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.RU.idinData.city": {
        "ID": "city",
        "Name": {
          "en": "city",
          "nl": ""
        },
        "Description": {
          "en": "The city at which you live",
          "nl": ""
        },
        "Index": 6,
        "CredentialTypeID": "idinData",
        "IssuerID": "RU",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.RU.idinData.dateOfBirth": {
        "ID": "dateOfBirth",
        "Name": {
          "en": "dateOfBirth",
          "nl": ""
        },
        "Description": {
          "en": "Your date of birth",
          "nl": ""
        },
        "Index": 2,
        "CredentialTypeID": "idinData",
        "IssuerID": "RU",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.RU.idinData.familyName": {
        "ID": "familyName",
        "Name": {
          "en": "familyName",
          "nl": ""
        },
        "Description": {
          "en": "Your family name",
          "nl": ""
        },
        "Index": 1,
        "CredentialTypeID": "idinData",
        "IssuerID": "RU",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.RU.idinData.initials": {
        "ID": "initials",
        "Name": {
          "en": "initials",
          "nl": ""
        },
        "Description": {
          "en": "First letters of your name(s)",
          "nl": ""
        },
        "Index": 0,
        "CredentialTypeID": "idinData",
        "IssuerID": "RU",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.RU.idinData.sex": {
        "ID": "sex",
        "Name": {
          "en": "sex",
          "nl": ""
        },
        "Description": {
          "en": "Your sex",
          "nl": ""
        },
        "Index": 3,
        "CredentialTypeID": "idinData",
        "IssuerID": "RU",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.RU.idinData.zipcode": {
        "ID": "zipcode",
        "Name": {
          "en": "zipcode",
          "nl": ""
        },
        "Description": {
          "en": "Your zipcode",
          "nl": ""
        },
        "Index": 5,
        "CredentialTypeID": "idinData",
        "IssuerID": "RU",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.RU.studentCard.level": {
        "ID": "level",
        "Name": {
          "en": "Type",
          "nl": "Soort"
        },
        "Description": {
          "en": "Whether you are a regular or PhD student",
          "nl": "Of u een gewone of PhD student bent"
        },
        "Index": 3,
        "CredentialTypeID": "studentCard",
        "IssuerID": "RU",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.RU.studentCard.studentCardNumber": {
        "ID": "studentCardNumber",
        "Name": {
          "en": "Student card number",
          "nl": "Studentenkaartnummer"
        },
        "Description": {
          "en": "The unique number of your student card",
          "nl": "Het unieke nummer op uw studentenkaart"
        },
        "Index": 1,
        "CredentialTypeID": "studentCard",
        "IssuerID": "RU",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.RU.studentCard.studentID": {
        "ID": "studentID",
        "Name": {
          "en": "Student number",
          "nl": "Studentnummer"
        },
        "Description": {
          "en": "Your student number",
          "nl": "Uw studentnummer"
        },
        "Index": 2,
        "CredentialTypeID": "studentCard",
        "IssuerID": "RU",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.RU.studentCard.university": {
        "ID": "university",
        "Name": {
          "en": "University",
          "nl": "Universiteit"
        },
        "Description": {
          "en": "The name of the university",
          "nl": "Naam van de universiteit"
        },
        "Index": 0,
        "CredentialTypeID": "studentCard",
        "IssuerID": "RU",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.aantalkinderen": {
        "ID": "aantalkinderen",
        "Optional": "true",
        "Name": {
          "en": "Inwonende kinderen",
          "nl": "Inwonende kinderen"
        },
        "Description": {
          "en": "Het aantal inwonende kinderen dat een ouder heeft",
          "nl": "Het aantal inwonende kinderen dat een ouder heeft"
        },
        "Index": 11,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.banksaldo": {
        "ID": "banksaldo",
        "Optional": "true",
        "Name": {
          "en": "Bank- en Spaarrekening",
          "nl": "Bank- en Spaarrekening"
        },
        "Description": {
          "en": "Het totaalbedrag dat op de rekeningen staat",
          "nl": "Het totaalbedrag dat op de rekeningen staat"
        },
        "Index": 7,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.bezittingen": {
        "ID": "bezittingen",
        "Optional": "true",
        "Name": {
          "en": "Vermogen waardevolle bezittingen",
          "nl": "Vermogen waardevolle bezittingen"
        },
        "Description": {
          "en": "Indicatie of iemand in het bezit is van (on)roerende goederen",
          "nl": " Indicatie of iemand in het bezit is van (on)roerende goederen"
        },
        "Index": 10,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.gezinssituatie": {
        "ID": "gezinssituatie",
        "Optional": "true",
        "Name": {
          "en": "Gezinssituatie",
          "nl": "Gezinssituatie"
        },
        "Description": {
          "en": "Status van de gezinssituatie, zoals: alleenstaand, alleenstaande ouder of met een partner is",
          "nl": "Status van de gezinssituatie, zoals: alleenstaand, alleenstaande ouder of met een partner is"
        },
        "Index": 1,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.inleven": {
        "ID": "inleven",
        "Optional": "true",
        "Name": {
          "en": "Alive",
          "nl": "In Leven"
        },
        "Description": {
          "en": "Indicatie dat een inwoner in leven is",
          "nl": "Indicatie dat een inwoner in leven is"
        },
        "Index": 0,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.inschrijvingopleiding": {
        "ID": "inschrijvingopleiding",
        "Optional": "true",
        "Name": {
          "en": "Inschrijving opleiding",
          "nl": "Inschrijving opleiding"
        },
        "Description": {
          "en": "Indicatie of iemand ingeschreven staat bij een opleiding",
          "nl": "Indicatie of iemand ingeschreven staat bij een opleiding"
        },
        "Index": 6,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.leeftijdkinderen": {
        "ID": "leeftijdkinderen",
        "Optional": "true",
        "Name": {
          "en": "Leeftijd kinderen",
          "nl": "Leeftijd kinderen"
        },
        "Description": {
          "en": "De leeftijd van kinderen van een ouder",
          "nl": "De leeftijd van kinderen van een ouder"
        },
        "Index": 12,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.medischebeperking": {
        "ID": "medischebeperking",
        "Optional": "true",
        "Name": {
          "en": "Medische Beperking",
          "nl": "Medische Beperking"
        },
        "Description": {
          "en": "Indicatie of iemand een medische beperking heeft",
          "nl": "Indicatie of iemand een medische beperking heeft"
        },
        "Index": 5,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.ontvangenbijstandsuitkering": {
        "ID": "ontvangenbijstandsuitkering",
        "Optional": "true",
        "Name": {
          "en": "Ontvangen Bijstandsuitkering",
          "nl": "Ontvangen Bijstandsuitkering"
        },
        "Description": {
          "en": "Indicatie of iemand een Bijstandsuitkering ontvangt",
          "nl": "Indicatie of iemand een Bijstandsuitkering ontvangt"
        },
        "Index": 21,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.ontvangenioawuitkering": {
        "ID": "ontvangenioawuitkering",
        "Optional": "true",
        "Name": {
          "en": "Ontvangen IOAW uitkering",
          "nl": "Ontvangen IOAW uitkering"
        },
        "Description": {
          "en": "Indicatie of iemand een IOAW uitkering ontvangt",
          "nl": "Indicatie of iemand een IOAW uitkering ontvangt"
        },
        "Index": 20,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.ontvangenwajong": {
        "ID": "ontvangenwajong",
        "Optional": "true",
        "Name": {
          "en": "Ontvangen Wajong",
          "nl": "Ontvangen Wajong"
        },
        "Description": {
          "en": "Indicatie of iemand Wajong ontvangt",
          "nl": "Indicatie of iemand Wajong ontvangt"
        },
        "Index": 4,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.overeenkomstkinderopvang": {
        "ID": "overeenkomstkinderopvang",
        "Optional": "true",
        "Name": {
          "en": "Overeenkomst Kinderopvang",
          "nl": "Overeenkomst Kinderopvang"
        },
        "Description": {
          "en": "Indicatie of er een overeenkomst met de kinderopvang aanwezig is",
          "nl": "Indicatie of er een overeenkomst met de kinderopvang aanwezig is"
        },
        "Index": 17,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.overzichtkinderopvang": {
        "ID": "overzichtkinderopvang",
        "Optional": "true",
        "Name": {
          "en": "Berekeningsoverzicht Kinderopvang",
          "nl": "Berekeningsoverzicht Kinderopvang"
        },
        "Description": {
          "en": "Bedragen op de het berekeningsoverzicht van de Kinderopvang",
          "nl": "Bedragen op de het berekeningsoverzicht van de Kinderopvang"
        },
        "Index": 18,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.rechtinkomenstoeslag": {
        "ID": "rechtinkomenstoeslag",
        "Optional": "true",
        "Name": {
          "en": "Recht Inkomenstoeslag",
          "nl": "Recht Inkomenstoeslag"
        },
        "Description": {
          "en": "Indicatie of iemand recht heeft op Inkomenstoeslag",
          "nl": "Indicatie of iemand recht heeft op Inkomenstoeslag"
        },
        "Index": 19,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.rechtwsf": {
        "ID": "rechtwsf",
        "Optional": "true",
        "Name": {
          "en": "Recht WSF",
          "nl": "Recht WSF"
        },
        "Description": {
          "en": "Indicatie of iemand recht heeft op WSF",
          "nl": "Indicatie of iemand recht heeft op WSF"
        },
        "Index": 3,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.rechtwtos": {
        "ID": "rechtwtos",
        "Optional": "true",
        "Name": {
          "en": "Recht WTOS",
          "nl": "Recht WTOS"
        },
        "Description": {
          "en": "Indicatie of iemand recht heeft op WTOS",
          "nl": "Indicatie of iemand recht heeft op WTOS"
        },
        "Index": 2,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.reintegratietraject": {
        "ID": "reintegratietraject",
        "Optional": "true",
        "Name": {
          "en": "Re-integratietraject",
          "nl": "Re-integratietraject"
        },
        "Description": {
          "en": "Indicatie of iemand een re-integratietraject volgt",
          "nl": "Indicatie of iemand een re-integratietraject volgt"
        },
        "Index": 13,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.schulden": {
        "ID": "schulden",
        "Optional": "true",
        "Name": {
          "en": "Schulden",
          "nl": "Schulden"
        },
        "Description": {
          "en": "Het totaalbedrag aan schulden",
          "nl": "Het totaalbedrag aan schulden"
        },
        "Index": 8,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.sociaalmedischeindicatie": {
        "ID": "sociaalmedischeindicatie",
        "Optional": "true",
        "Name": {
          "en": "Sociaal Medische Indicatie",
          "nl": "Sociaal Medische Indicatie"
        },
        "Description": {
          "en": "Of iemand een Sociaal Medische Indicatie heeft",
          "nl": "Of iemand een Sociaal Medische Indicatie heeft"
        },
        "Index": 16,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.svbuitkering": {
        "ID": "svbuitkering",
        "Optional": "true",
        "Name": {
          "en": "Ontvangen SVB uitkering",
          "nl": "Ontvangen SVB uitkering"
        },
        "Description": {
          "en": "Indicatie of iemand een uitkering ontvangt van SVB",
          "nl": "Indicatie of iemand een uitkering ontvangt van SVB"
        },
        "Index": 15,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.uwvuitkering": {
        "ID": "uwvuitkering",
        "Optional": "true",
        "Name": {
          "en": "Ontvangen UWV uitkering",
          "nl": "Ontvangen UWV uitkering"
        },
        "Description": {
          "en": "Indicatie of iemand een uitkering ontvangt van UWV",
          "nl": "Indicatie of iemand een uitkering ontvangt van UWV"
        },
        "Index": 14,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.TWIpilot.TWIattributes.waardepapieren": {
        "ID": "waardepapieren",
        "Optional": "true",
        "Name": {
          "en": "Vermogen waardepapieren",
          "nl": "Vermogen waardepapieren"
        },
        "Description": {
          "en": "Het totaalbedrag aan waardepapieren",
          "nl": "Het totaalbedrag aan waardepapieren"
        },
        "Index": 9,
        "CredentialTypeID": "TWIattributes",
        "IssuerID": "TWIpilot",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.alliander.connection.eanelec": {
        "ID": "eanelec",
        "Name": {
          "en": "Electricity meter code",
          "nl": "Electriciteitsmetercode"
        },
        "Description": {
          "en": "EAN code of your electricity connection",
          "nl": "EAN-code van uw electriciteitsaansluiting"
        },
        "Index": 1,
        "CredentialTypeID": "connection",
        "IssuerID": "alliander",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.alliander.connection.eangas": {
        "ID": "eangas",
        "Name": {
          "en": "Gas meter code",
          "nl": "Gasmetercode"
        },
        "Description": {
          "en": "EAN code of your gas connection",
          "nl": "EAN-code van uw gassaansluiting"
        },
        "Index": 0,
        "CredentialTypeID": "connection",
        "IssuerID": "alliander",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.alliander.connection.pseudonym": {
        "ID": "pseudonym",
        "Name": {
          "en": "Pseudonym",
          "nl": "Pseudoniem"
        },
        "Description": {
          "en": "Pseudonym for pseudonymous communication",
          "nl": "Pseudoniem voor pseudonieme communicatie"
        },
        "Index": 2,
        "CredentialTypeID": "connection",
        "IssuerID": "alliander",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.amsterdam.openStadBallot.ballot": {
        "ID": "ballot",
        "Name": {
          "en": "Ballot",
          "nl": "Stembiljet"
        },
        "Description": {
          "en": "The right to vote",
          "nl": "Het recht om te stemmen"
        },
        "Index": 0,
        "CredentialTypeID": "openStadBallot",
        "IssuerID": "amsterdam",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.amountPaid": {
        "ID": "amountPaid",
        "Name": {
          "en": "Amount paid",
          "nl": "Uitbetaald bedrag"
        },
        "Description": {
          "en": "Column 17: Amount paid (column 3-7-15-16)",
          "nl": "Kolom 17: Uitbetaald bedrag (kolom 3-7-15-16)"
        },
        "Index": 14,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.careerSavingsPlanDiscount": {
        "ID": "careerSavingsPlanDiscount",
        "Name": {
          "en": "Career savings plan discount",
          "nl": "Levensloop_verlofkorting"
        },
        "Description": {
          "en": "Column 19: Career savings plan discount",
          "nl": "Kolom 19: Levensloop_verlofkorting"
        },
        "Index": 16,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.deductedWorkInsurance": {
        "ID": "deductedWorkInsurance",
        "Name": {
          "en": "Deducted work discount",
          "nl": "Verrekende arbeidskorting"
        },
        "Description": {
          "en": "Column 18: Deducted work discount",
          "nl": "Kolom 18: Verrekende arbeidskorting"
        },
        "Index": 15,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.disabledPersonDiscount": {
        "ID": "disabledPersonDiscount",
        "Name": {
          "en": "Jonggehandicaptenkorting",
          "nl": "Jonggehandicaptenkorting"
        },
        "Description": {
          "en": "Disabled person discount applied",
          "nl": "Jonggehandicaptenkorting toegepast"
        },
        "Index": 2,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.employeeInsuranceLawPay": {
        "ID": "employeeInsuranceLawPay",
        "Name": {
          "en": "Pay for Employee Insurance law",
          "nl": "Loon voor de werknemersverzekeringen"
        },
        "Description": {
          "en": "Column 8: Pay for Employee Insurance law",
          "nl": "Kolom 8: Loon voor de werknemersverzekeringen"
        },
        "Index": 9,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.employer": {
        "ID": "employer",
        "Name": {
          "en": "Werkgever",
          "nl": "Werkgever"
        },
        "Description": {
          "en": "The employer issuing this payroll",
          "nl": "De werkgever die de loonstaat verstrekt"
        },
        "Index": 0,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.healthInsuranceLawPay": {
        "ID": "healthInsuranceLawPay",
        "Name": {
          "en": "Pay for Health Insurance law",
          "nl": "Loon voor de Zorgverzekeringswet"
        },
        "Description": {
          "en": "Column 12: Pay for Health Insurance law",
          "nl": "Kolom 12: Loon voor de Zorgverzekeringswet"
        },
        "Index": 10,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.incomeContractNumber": {
        "ID": "incomeContractNumber",
        "Name": {
          "en": "Number Income contract",
          "nl": "Nummer Inkomstenverhouding"
        },
        "Description": {
          "en": "Column 2: Number Income contract",
          "nl": "Kolom 2: Nummer Inkomstenverhouding"
        },
        "Index": 4,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.payFromFunds": {
        "ID": "payFromFunds",
        "Name": {
          "en": "Pay from funds",
          "nl": "Uitkeringen uit fondsen"
        },
        "Description": {
          "en": "Column 5: Pay from funds",
          "nl": "Kolom 5: Fooien en uitkeringen uit fondsen"
        },
        "Index": 7,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.payInMoney": {
        "ID": "payInMoney",
        "Name": {
          "en": "Pay in money",
          "nl": "Loon in geld"
        },
        "Description": {
          "en": "Column 3: Pay in money",
          "nl": "Kolom 3: Loon in geld"
        },
        "Index": 5,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.payNotInMoney": {
        "ID": "payNotInMoney",
        "Name": {
          "en": "Pay not in money",
          "nl": "Loon anders dan in geld"
        },
        "Description": {
          "en": "Column 4: Pay not in money",
          "nl": "Kolom 4: Loon anders dan in geld"
        },
        "Index": 6,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.payrollTaxDiscount": {
        "ID": "payrollTaxDiscount",
        "Name": {
          "en": "Loonheffingkorting",
          "nl": "Loonheffingkorting"
        },
        "Description": {
          "en": "Payroll tax discount applied",
          "nl": "Loonheffingkorting toegepast"
        },
        "Index": 1,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.payrollTimeframe": {
        "ID": "payrollTimeframe",
        "Name": {
          "en": "Timeframe",
          "nl": "Loontijdvak"
        },
        "Description": {
          "en": "Column 1: Timeframe of this payroll",
          "nl": "Kolom 1: Tijdvak van de loonstaat"
        },
        "Index": 3,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.rebatesBeforeTax": {
        "ID": "rebatesBeforeTax",
        "Name": {
          "en": "Rebates before tax",
          "nl": "Aftrekposten voor alle heffingen"
        },
        "Description": {
          "en": "Column 7: Rebates before tax",
          "nl": "Kolom 7: Aftrekposten voor alle heffingen"
        },
        "Index": 8,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.socialInsurancePay": {
        "ID": "socialInsurancePay",
        "Name": {
          "en": "Pay for payroll tax and social insurance law",
          "nl": "Loon voor de loonbelasting/volksverzekeringen"
        },
        "Description": {
          "en": "Column 12: Pay for payroll tax and social insurance law",
          "nl": "Kolom 12: Loon voor de loonbelasting/volksverzekeringen"
        },
        "Index": 11,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.socialInsurancePremium": {
        "ID": "socialInsurancePremium",
        "Name": {
          "en": "Payroll tax and social insurance premium",
          "nl": "Ingehouden loonbelasting/premie volksverzekeringen"
        },
        "Description": {
          "en": "Column 15: Payroll tax and social insurance premium",
          "nl": "Kolom 15: Ingehouden loonbelasting/premie volksverzekeringen"
        },
        "Index": 12,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.loonstaat.withheldZvwPay": {
        "ID": "withheldZvwPay",
        "Name": {
          "en": "Payroll tax for Medical Care Insurance law",
          "nl": "Ingehouden bijdrage Zvw"
        },
        "Description": {
          "en": "Column 16: Payroll tax for Medical Care Insurance law",
          "nl": "Kolom 16: Ingehouden bijdrage Zvw"
        },
        "Index": 13,
        "CredentialTypeID": "loonstaat",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.paysheet.employeePremium": {
        "ID": "employeePremium",
        "Name": {
          "en": "Employee premium",
          "nl": "Werknemers premie"
        },
        "Description": {
          "en": "Employee premium",
          "nl": "Werknemers premie"
        },
        "Index": 3,
        "CredentialTypeID": "paysheet",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.paysheet.grossSalary": {
        "ID": "grossSalary",
        "Name": {
          "en": "Gross salary",
          "nl": "Brutoloon"
        },
        "Description": {
          "en": "Gross salary",
          "nl": "Brutoloon"
        },
        "Index": 0,
        "CredentialTypeID": "paysheet",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.paysheet.grossSalaryComponents": {
        "ID": "grossSalaryComponents",
        "Name": {
          "en": "Gross salary components",
          "nl": "Bruto componenten"
        },
        "Description": {
          "en": "Gross salary components",
          "nl": "Bruto componenten"
        },
        "Index": 1,
        "CredentialTypeID": "paysheet",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.paysheet.netSalaryAllocations": {
        "ID": "netSalaryAllocations",
        "Name": {
          "en": "Net salary allocations",
          "nl": "Netto toekenningen"
        },
        "Description": {
          "en": "Net salary allocations",
          "nl": "Netto toekenningen"
        },
        "Index": 4,
        "CredentialTypeID": "paysheet",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.paysheet.netSalaryDeductions": {
        "ID": "netSalaryDeductions",
        "Name": {
          "en": "Net salary deductions",
          "nl": "Netto inhoudingen"
        },
        "Description": {
          "en": "Net salary deductions",
          "nl": "Netto inhoudingen"
        },
        "Index": 5,
        "CredentialTypeID": "paysheet",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.paysheet.solidarityContribution": {
        "ID": "solidarityContribution",
        "Name": {
          "en": "Solidarity contribution",
          "nl": "Solidariteitsbijdrage"
        },
        "Description": {
          "en": "Solidarity contribution",
          "nl": "Solidariteitsbijdrage"
        },
        "Index": 7,
        "CredentialTypeID": "paysheet",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.paysheet.vtEmployer": {
        "ID": "vtEmployer",
        "Name": {
          "en": "Vacation allowance employer",
          "nl": "Vakantie Toeslag werkgever"
        },
        "Description": {
          "en": "Vacation allowance employer",
          "nl": "Vakantie Toeslag werkgever"
        },
        "Index": 6,
        "CredentialTypeID": "paysheet",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.asito.paysheet.wnPremium": {
        "ID": "wnPremium",
        "Name": {
          "en": "WN premium",
          "nl": "WN premie"
        },
        "Description": {
          "en": "WN premium",
          "nl": "WN premie"
        },
        "Index": 2,
        "CredentialTypeID": "paysheet",
        "IssuerID": "asito",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.belastingdienst.verzamelinkomen.box1": {
        "ID": "box1",
        "Name": {
          "en": "Box 1",
          "nl": "Box 1"
        },
        "Description": {
          "en": "Box 1: Income from work, or social security benefits and owned house",
          "nl": "Box 1: Inkomsten uit werk, of een uitkering, en de eigen woning"
        },
        "Index": 2,
        "CredentialTypeID": "verzamelinkomen",
        "IssuerID": "belastingdienst",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.belastingdienst.verzamelinkomen.box2": {
        "ID": "box2",
        "Name": {
          "en": "Box 2",
          "nl": "Box 2"
        },
        "Description": {
          "en": "Box 2: Income from stocks and dividends",
          "nl": "Box 2: Inkomsten uit aandelen en dividenden"
        },
        "Index": 3,
        "CredentialTypeID": "verzamelinkomen",
        "IssuerID": "belastingdienst",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.belastingdienst.verzamelinkomen.box3": {
        "ID": "box3",
        "Name": {
          "en": "Box 3",
          "nl": "Box 3"
        },
        "Description": {
          "en": "Box 3: Yields from savings and investments",
          "nl": "Box 3: Opbrengsten uit sparen en beleggen"
        },
        "Index": 4,
        "CredentialTypeID": "verzamelinkomen",
        "IssuerID": "belastingdienst",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.belastingdienst.verzamelinkomen.incomelevel": {
        "ID": "incomelevel",
        "Name": {
          "en": "level of income",
          "nl": "Inkomensniveau"
        },
        "Description": {
          "en": "Your level of income relative to the general population.",
          "nl": "Uw inkomensniveau, relatief aan het gemiddelde inkomen."
        },
        "Index": 5,
        "CredentialTypeID": "verzamelinkomen",
        "IssuerID": "belastingdienst",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.belastingdienst.verzamelinkomen.totalincome": {
        "ID": "totalincome",
        "Name": {
          "en": "Total year income",
          "nl": "Totale verzamelinkomen"
        },
        "Description": {
          "en": "Your total year income",
          "nl": "Uw totale verzamelinkomen"
        },
        "Index": 1,
        "CredentialTypeID": "verzamelinkomen",
        "IssuerID": "belastingdienst",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.belastingdienst.verzamelinkomen.year": {
        "ID": "year",
        "Name": {
          "en": "Year",
          "nl": "Jaar"
        },
        "Description": {
          "en": "The tax year",
          "nl": "Het belastingjaar"
        },
        "Index": 0,
        "CredentialTypeID": "verzamelinkomen",
        "IssuerID": "belastingdienst",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.belastingdienst.verzamelinkomenhuishouden.belowexceptionsocialhousing": {
        "ID": "belowexceptionsocialhousing",
        "Name": {
          "en": "Below social housing exception threshold",
          "nl": "Onder uitzonderingsgrens Sociale Huurwoning"
        },
        "Description": {
          "en": "Is your household's total year income below the exception threshold for social housing?",
          "nl": "Valt het totale jaarinkomen van uw huishouden onder de uitzonderingsgrens Sociale Huurwoning?"
        },
        "Index": 3,
        "CredentialTypeID": "verzamelinkomenhuishouden",
        "IssuerID": "belastingdienst",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.belastingdienst.verzamelinkomenhuishouden.belowsocialhousing": {
        "ID": "belowsocialhousing",
        "Name": {
          "en": "Below social housing threshold",
          "nl": "Onder inkomensgrens Sociale Huurwoning"
        },
        "Description": {
          "en": "Is your household's total year income below the social housing threshold?",
          "nl": "Valt het totale jaarinkomen van uw huishouden onder de inkomensgrens Sociale Huurwoning?"
        },
        "Index": 2,
        "CredentialTypeID": "verzamelinkomenhuishouden",
        "IssuerID": "belastingdienst",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.belastingdienst.verzamelinkomenhuishouden.totalincome": {
        "ID": "totalincome",
        "Name": {
          "en": "Total year income houshold",
          "nl": "Totale verzamelinkomen huishouden"
        },
        "Description": {
          "en": "Your household's total year income",
          "nl": "Het totale verzamelinkomen van uw huishouden"
        },
        "Index": 1,
        "CredentialTypeID": "verzamelinkomenhuishouden",
        "IssuerID": "belastingdienst",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.belastingdienst.verzamelinkomenhuishouden.year": {
        "ID": "year",
        "Name": {
          "en": "Year",
          "nl": "Jaar"
        },
        "Description": {
          "en": "The tax year",
          "nl": "Het belastingjaar"
        },
        "Index": 0,
        "CredentialTypeID": "verzamelinkomenhuishouden",
        "IssuerID": "belastingdienst",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.chipsoft.bsn.bsn": {
        "ID": "bsn",
        "Name": {
          "en": "BSN from healthcare",
          "nl": "BSN vanuit de zorg"
        },
        "Description": {
          "en": "Your Dutch Citizen service number (BSN) from healthcare",
          "nl": "Uw Burgerservicenummer (BSN) vanuit de zorg"
        },
        "Index": 0,
        "DisplayIndex": 0,
        "CredentialTypeID": "bsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.chipsoft.bsn.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth",
          "nl": "Uw geboortedatum"
        },
        "Index": 5,
        "DisplayIndex": 5,
        "CredentialTypeID": "bsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.chipsoft.bsn.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Geslachtsnaam"
        },
        "Description": {
          "en": "Your family name, as given to you at birth",
          "nl": "Uw achternaam, zoals aan u toegekend bij uw geboorte"
        },
        "Index": 4,
        "DisplayIndex": 4,
        "CredentialTypeID": "bsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.chipsoft.bsn.firstnames": {
        "ID": "firstnames",
        "Name": {
          "en": "First names",
          "nl": "Voornamen"
        },
        "Description": {
          "en": "Your first names",
          "nl": "Uw voornamen"
        },
        "Index": 2,
        "DisplayIndex": 2,
        "CredentialTypeID": "bsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.chipsoft.bsn.initials": {
        "ID": "initials",
        "Name": {
          "en": "Initials",
          "nl": "Voorletters"
        },
        "Description": {
          "en": "Your initials, abbreviating your first names",
          "nl": "Uw voorletters, een afkorting van uw voornamen"
        },
        "Index": 1,
        "DisplayIndex": 1,
        "CredentialTypeID": "bsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.chipsoft.bsn.prefix": {
        "ID": "prefix",
        "Optional": "true",
        "Name": {
          "en": "Prefix",
          "nl": "Voorvoegsel"
        },
        "Description": {
          "en": "Prefix of your family name",
          "nl": "Voorvoegsel van uw achternaam"
        },
        "Index": 3,
        "DisplayIndex": 3,
        "CredentialTypeID": "bsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.enschede.bijstandsgerechtigd.bijstandsgerechtigd": {
        "ID": "bijstandsgerechtigd",
        "Name": {
          "en": "Bijstandsgerechtigd",
          "nl": "Bijstandsgerechtigd"
        },
        "Description": {
          "en": "Indicatie dat een inwoner bijstandsgerechtigd is",
          "nl": "Indicatie dat een inwoner bijstandsgerechtigd is"
        },
        "Index": 0,
        "CredentialTypeID": "bijstandsgerechtigd",
        "IssuerID": "enschede",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.forus.demoKindpakket.kindpakketEligible": {
        "ID": "kindpakketEligible",
        "Name": {
          "en": "Eligible for kindpakket",
          "nl": "Recht op kindpakket"
        },
        "Description": {
          "en": "Eligible for kindpakket",
          "nl": "Recht op kindpakket"
        },
        "Index": 0,
        "CredentialTypeID": "demoKindpakket",
        "IssuerID": "forus",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.forus.demoKindpakket.numChildren": {
        "ID": "numChildren",
        "Name": {
          "en": "Number of children",
          "nl": "Aantal kinderen"
        },
        "Description": {
          "en": "Number of children",
          "nl": "Aantal kinderen"
        },
        "Index": 1,
        "CredentialTypeID": "demoKindpakket",
        "IssuerID": "forus",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gebiedonline.locality.district": {
        "ID": "district",
        "Name": {
          "en": "Stakeholder district",
          "nl": "Belanghebbende in gebied / stadsdeel"
        },
        "Description": {
          "en": "Lives or works in district",
          "nl": "Belanghebbende; woont of werkt in gebied of stadsdeel"
        },
        "Index": 2,
        "CredentialTypeID": "locality",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gebiedonline.locality.locality": {
        "ID": "locality",
        "Name": {
          "en": "Stakeholder local neighbourhood",
          "nl": "Belanghebbende in locale buurt"
        },
        "Description": {
          "en": "Lives or works in local (sub-) neighbourhood",
          "nl": "Belanghebbende; woont of werkt in de buurt"
        },
        "Index": 0,
        "CredentialTypeID": "locality",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gebiedonline.locality.municipality": {
        "ID": "municipality",
        "Name": {
          "en": "Stakeholder municipality",
          "nl": "Belanghebbende in de stad of plaats"
        },
        "Description": {
          "en": "Lives or works in municipality",
          "nl": "Belanghebbende; woont of werkt in plaats"
        },
        "Index": 3,
        "CredentialTypeID": "locality",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gebiedonline.locality.neighbourhood": {
        "ID": "neighbourhood",
        "Name": {
          "en": "Stakeholder neighbourhood",
          "nl": "Belanghebbende in wijk"
        },
        "Description": {
          "en": "Lives or works in neighbourhood",
          "nl": "Belanghebbende; woont of werkt in de wijk"
        },
        "Index": 1,
        "CredentialTypeID": "locality",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gebiedonline.locality2.homePostcodeDigits": {
        "ID": "homePostcodeDigits",
        "Name": {
          "en": "4 digits of postcode of residential address",
          "nl": "4 cijfers van de postcode van het woonadres"
        },
        "Description": {
          "en": "Lives in the city/neightborhood with the given 4 digits of the postal code",
          "nl": "Woont in het gebied aangeduid met deze 4 cijfers van de postcode"
        },
        "Index": 0,
        "CredentialTypeID": "locality2",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gebiedonline.locality2.workPostcodeDigits": {
        "ID": "workPostcodeDigits",
        "Name": {
          "en": "4 digits of postcode of work address",
          "nl": "4 cijfers van de postcode van het werkadres"
        },
        "Description": {
          "en": "Works or has economic ties with the area denoted ny the four postcode digits",
          "nl": "Werkt of heeft economische binding met het gebied aangeduid met de 4 cijfers van de postcode"
        },
        "Index": 1,
        "CredentialTypeID": "locality2",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gebiedonline.stakeholder.logincode": {
        "ID": "logincode",
        "Name": {
          "en": "Login code of Gebiedonline",
          "nl": "Login code van Gebiedonline"
        },
        "Description": {
          "en": "Person can log into any Gebiedonline platform with specified code.",
          "nl": "Persoon kan in een Gebiedonline platform inloggen met code."
        },
        "Index": 0,
        "CredentialTypeID": "stakeholder",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.address.city": {
        "ID": "city",
        "Name": {
          "en": "City",
          "nl": "Woonplaats"
        },
        "Description": {
          "en": "Your city of residence",
          "nl": "Uw woonplaats"
        },
        "Index": 4,
        "CredentialTypeID": "address",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.address.houseNumber": {
        "ID": "houseNumber",
        "Optional": "true",
        "Name": {
          "en": "House number",
          "nl": "Huisnummer"
        },
        "Description": {
          "en": "Your house number, letter and/or addition",
          "nl": "Uw huisnummer, letter en/of toevoeging"
        },
        "Index": 1,
        "CredentialTypeID": "address",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.address.municipality": {
        "ID": "municipality",
        "Name": {
          "en": "Municipality",
          "nl": "Gemeente"
        },
        "Description": {
          "en": "Your municipality",
          "nl": "Uw gemeente"
        },
        "Index": 3,
        "CredentialTypeID": "address",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.address.street": {
        "ID": "street",
        "Name": {
          "en": "Street",
          "nl": "Straat"
        },
        "Description": {
          "en": "Your street",
          "nl": "Uw straat"
        },
        "Index": 0,
        "CredentialTypeID": "address",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.address.zipcode": {
        "ID": "zipcode",
        "Name": {
          "en": "Zip code",
          "nl": "Postcode"
        },
        "Description": {
          "en": "Your zip code",
          "nl": "Uw postcode"
        },
        "Index": 2,
        "CredentialTypeID": "address",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.bsn": {
        "ID": "bsn",
        "Name": {
          "en": "BSN",
          "nl": "BSN"
        },
        "Description": {
          "en": "Your Dutch Citizen service number (BSN)",
          "nl": "Uw Burgerservicenummer (BSN)"
        },
        "Index": 16,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.cityofbirth": {
        "ID": "cityofbirth",
        "Name": {
          "en": "City of birth",
          "nl": "Geboorteplaats"
        },
        "Description": {
          "en": "Your city of birth",
          "nl": "Uw geboorteplaats"
        },
        "Index": 9,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.countryofbirth": {
        "ID": "countryofbirth",
        "Name": {
          "en": "Country of birth",
          "nl": "Geboorteland"
        },
        "Description": {
          "en": "Your country of birth",
          "nl": "Uw geboorteland"
        },
        "Index": 10,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth",
          "nl": "Uw geboortedatum"
        },
        "Index": 8,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.digidlevel": {
        "ID": "digidlevel",
        "Name": {
          "en": "DigiD assurance level",
          "nl": "DigiD betrouwbaarheidsniveau"
        },
        "Description": {
          "en": "Het DigiD betrouwbaarheidsniveau waarmee uw identiteit is vastgesteld",
          "nl": "The DigiD assurance level with which your identity was verified"
        },
        "Index": 17,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Geslachtsnaam"
        },
        "Description": {
          "en": "Your family name, as given to you at birth",
          "nl": "Uw achternaam, zoals aan u toegekend bij uw geboorte"
        },
        "Index": 3,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.firstnames": {
        "ID": "firstnames",
        "Name": {
          "en": "First names",
          "nl": "Voornamen"
        },
        "Description": {
          "en": "Your first names",
          "nl": "Uw voornamen"
        },
        "Index": 1,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.fullname": {
        "ID": "fullname",
        "Optional": "true",
        "Name": {
          "en": "Full name",
          "nl": "Volledige naam"
        },
        "Description": {
          "en": "Your full name",
          "nl": "Uw volledige naam"
        },
        "Index": 4,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.gender": {
        "ID": "gender",
        "Name": {
          "en": "Gender",
          "nl": "Geslacht"
        },
        "Description": {
          "en": "Your gender",
          "nl": "Uw geslacht"
        },
        "Index": 5,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.initials": {
        "ID": "initials",
        "Name": {
          "en": "Initials",
          "nl": "Voorletters"
        },
        "Description": {
          "en": "Your initials, abbreviating your first names",
          "nl": "Uw voorletters, een afkorting van uw voornamen"
        },
        "Index": 0,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.nationality": {
        "ID": "nationality",
        "Optional": "true",
        "Name": {
          "en": "Dutch nationality",
          "nl": "Nederlandse nationaliteit"
        },
        "Description": {
          "en": "Whether you have the dutch nationality",
          "nl": "Of u de Nederlandse nationaliteit bezit"
        },
        "Index": 6,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.over12": {
        "ID": "over12",
        "Name": {
          "en": "Over 12",
          "nl": "Ouder dan 12"
        },
        "Description": {
          "en": "Whether you are over 12",
          "nl": "Of u ouder dan 12 bent"
        },
        "Index": 11,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.over16": {
        "ID": "over16",
        "Name": {
          "en": "Over 16",
          "nl": "Ouder dan 16"
        },
        "Description": {
          "en": "Whether you are over 16",
          "nl": "Of u ouder dan 16 bent"
        },
        "Index": 12,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.over18": {
        "ID": "over18",
        "Name": {
          "en": "Over 18",
          "nl": "Ouder dan 18"
        },
        "Description": {
          "en": "Whether you are over 18",
          "nl": "Of u ouder dan 18 bent"
        },
        "Index": 13,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.over21": {
        "ID": "over21",
        "Name": {
          "en": "Over 21",
          "nl": "Ouder dan 21"
        },
        "Description": {
          "en": "Whether you are over 21",
          "nl": "Of u ouder dan 21 bent"
        },
        "Index": 14,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.over65": {
        "ID": "over65",
        "Name": {
          "en": "Over 65",
          "nl": "Ouder dan 65"
        },
        "Description": {
          "en": "Whether you are over 65",
          "nl": "Of u ouder dan 65 bent"
        },
        "Index": 15,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.prefix": {
        "ID": "prefix",
        "Name": {
          "en": "Prefix",
          "nl": "Voorvoegsel"
        },
        "Description": {
          "en": "Prefix of your family name",
          "nl": "Voorvoegsel van uw achternaam"
        },
        "Index": 2,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeente.personalData.surname": {
        "ID": "surname",
        "Name": {
          "en": "Surname",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your full family name: your family name or (a combination with) that of your partner",
          "nl": "Uw volledige achternaam: uw geslachtsnaam of (een combinatie met) die van uw partner"
        },
        "Index": 7,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.address.city": {
        "ID": "city",
        "Name": {
          "en": "City",
          "nl": "Woonplaats"
        },
        "Description": {
          "en": "Your city of residence",
          "nl": "Uw woonplaats"
        },
        "Index": 4,
        "CredentialTypeID": "address",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.address.houseNumber": {
        "ID": "houseNumber",
        "Optional": "true",
        "Name": {
          "en": "House number",
          "nl": "Huisnummer"
        },
        "Description": {
          "en": "Your house number, letter and/or addition",
          "nl": "Uw huisnummer, letter en/of toevoeging"
        },
        "Index": 1,
        "CredentialTypeID": "address",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.address.municipality": {
        "ID": "municipality",
        "Name": {
          "en": "Municipality",
          "nl": "Gemeente"
        },
        "Description": {
          "en": "Your municipality",
          "nl": "Uw gemeente"
        },
        "Index": 3,
        "CredentialTypeID": "address",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.address.street": {
        "ID": "street",
        "Name": {
          "en": "Street",
          "nl": "Straat"
        },
        "Description": {
          "en": "Your street",
          "nl": "Uw straat"
        },
        "Index": 0,
        "CredentialTypeID": "address",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.address.zipcode": {
        "ID": "zipcode",
        "Name": {
          "en": "Zip code",
          "nl": "Postcode"
        },
        "Description": {
          "en": "Your zip code",
          "nl": "Uw postcode"
        },
        "Index": 2,
        "CredentialTypeID": "address",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.bsn": {
        "ID": "bsn",
        "Name": {
          "en": "BSN",
          "nl": "BSN"
        },
        "Description": {
          "en": "Your Dutch Citizen service number (BSN)",
          "nl": "Uw Burgerservicenummer (BSN)"
        },
        "Index": 14,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth",
          "nl": "Uw geboortedatum"
        },
        "Index": 8,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.digidlevel": {
        "ID": "digidlevel",
        "Name": {
          "en": "DigiD assurance level",
          "nl": "DigiD betrouwbaarheidsniveau"
        },
        "Description": {
          "en": "Het DigiD betrouwbaarheidsniveau waarmee uw identiteit is vastgesteld",
          "nl": "The DigiD assurance level with which your identity was verified"
        },
        "Index": 15,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Geslachtsnaam"
        },
        "Description": {
          "en": "Your family name, as given to you at birth",
          "nl": "Uw achternaam, zoals aan u toegekend bij uw geboorte"
        },
        "Index": 3,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.firstnames": {
        "ID": "firstnames",
        "Name": {
          "en": "First names",
          "nl": "Voornamen"
        },
        "Description": {
          "en": "Your first names",
          "nl": "Uw voornamen"
        },
        "Index": 1,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.fullname": {
        "ID": "fullname",
        "Optional": "true",
        "Name": {
          "en": "Full name",
          "nl": "Volledige naam"
        },
        "Description": {
          "en": "Your full name",
          "nl": "Uw volledige naam"
        },
        "Index": 4,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.gender": {
        "ID": "gender",
        "Name": {
          "en": "Gender",
          "nl": "Geslacht"
        },
        "Description": {
          "en": "Your gender",
          "nl": "Uw geslacht"
        },
        "Index": 5,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.initials": {
        "ID": "initials",
        "Name": {
          "en": "Initials",
          "nl": "Voorletters"
        },
        "Description": {
          "en": "Your initials, abbreviating your first names",
          "nl": "Uw voorletters, een afkorting van uw voornamen"
        },
        "Index": 0,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.nationality": {
        "ID": "nationality",
        "Optional": "true",
        "Name": {
          "en": "Dutch nationality",
          "nl": "Nederlandse nationaliteit"
        },
        "Description": {
          "en": "Whether you have the dutch nationality",
          "nl": "Of u de Nederlandse nationaliteit bezit"
        },
        "Index": 6,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.over12": {
        "ID": "over12",
        "Name": {
          "en": "Over 12",
          "nl": "Ouder dan 12"
        },
        "Description": {
          "en": "Whether you are over 12",
          "nl": "Of u ouder dan 12 bent"
        },
        "Index": 9,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.over16": {
        "ID": "over16",
        "Name": {
          "en": "Over 16",
          "nl": "Ouder dan 16"
        },
        "Description": {
          "en": "Whether you are over 16",
          "nl": "Of u ouder dan 16 bent"
        },
        "Index": 10,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.over18": {
        "ID": "over18",
        "Name": {
          "en": "Over 18",
          "nl": "Ouder dan 18"
        },
        "Description": {
          "en": "Whether you are over 18",
          "nl": "Of u ouder dan 18 bent"
        },
        "Index": 11,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.over21": {
        "ID": "over21",
        "Name": {
          "en": "Over 21",
          "nl": "Ouder dan 21"
        },
        "Description": {
          "en": "Whether you are over 21",
          "nl": "Of u ouder dan 21 bent"
        },
        "Index": 12,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.over65": {
        "ID": "over65",
        "Name": {
          "en": "Over 65",
          "nl": "Ouder dan 65"
        },
        "Description": {
          "en": "Whether you are over 65",
          "nl": "Of u ouder dan 65 bent"
        },
        "Index": 13,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.prefix": {
        "ID": "prefix",
        "Optional": "true",
        "Name": {
          "en": "Prefix",
          "nl": "Voorvoegsel"
        },
        "Description": {
          "en": "Prefix of your family name",
          "nl": "Voorvoegsel van uw achternaam"
        },
        "Index": 2,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.gemeenten.personalData.surname": {
        "ID": "surname",
        "Name": {
          "en": "Surname",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your full family name: your family name or (a combination with) that of your partner",
          "nl": "Uw volledige achternaam: uw geslachtsnaam of (een combinatie met) die van uw partner"
        },
        "Index": 7,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeenten",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.haarlem.medewerker.organisatie": {
        "ID": "organisatie",
        "Name": {
          "en": "Organisation",
          "nl": "Organisatie"
        },
        "Description": {
          "en": "Organisation within this municipality",
          "nl": "Organisatie binnen gemeente"
        },
        "Index": 1,
        "CredentialTypeID": "medewerker",
        "IssuerID": "haarlem",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.haarlem.medewerker.personeelsnummer": {
        "ID": "personeelsnummer",
        "Name": {
          "en": "Employee number",
          "nl": "Personeelsnummer"
        },
        "Description": {
          "en": "Unique number for employee registration",
          "nl": "Uniek nummer voor personeelregistratie"
        },
        "Index": 0,
        "CredentialTypeID": "medewerker",
        "IssuerID": "haarlem",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.ideal.ideal.bic": {
        "ID": "bic",
        "Name": {
          "en": "BIC",
          "nl": "BIC"
        },
        "Description": {
          "en": "The Bank Identifier Code of your bank",
          "nl": "De Bank Identifier Code van uw bank"
        },
        "Index": 2,
        "CredentialTypeID": "ideal",
        "IssuerID": "ideal",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.ideal.ideal.fullname": {
        "ID": "fullname",
        "Name": {
          "en": "Account holder",
          "nl": "Rekeninghouder"
        },
        "Description": {
          "en": "Your full name, as registered at your bank",
          "nl": "Uw volledige naam, zoals geregistreerd bij uw bank"
        },
        "Index": 0,
        "CredentialTypeID": "ideal",
        "IssuerID": "ideal",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.ideal.ideal.iban": {
        "ID": "iban",
        "Name": {
          "en": "IBAN",
          "nl": "IBAN"
        },
        "Description": {
          "en": "The IBAN of your bank account",
          "nl": "De IBAN van uw bankrekening"
        },
        "Index": 1,
        "CredentialTypeID": "ideal",
        "IssuerID": "ideal",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.ageLimits.over12": {
        "ID": "over12",
        "Name": {
          "en": "Over 12",
          "nl": "Ouder dan 12"
        },
        "Description": {
          "en": "If you are over 12",
          "nl": "Of u ouder dan 12 bent"
        },
        "Index": 0,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.ageLimits.over16": {
        "ID": "over16",
        "Name": {
          "en": "Over 16",
          "nl": "Ouder dan 16"
        },
        "Description": {
          "en": "If you are over 16",
          "nl": "Of u ouder dan 16 bent"
        },
        "Index": 1,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.ageLimits.over18": {
        "ID": "over18",
        "Name": {
          "en": "Over 18",
          "nl": "Ouder dan 18"
        },
        "Description": {
          "en": "If you are over 18",
          "nl": "Of u ouder dan 18 bent"
        },
        "Index": 2,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.ageLimits.over21": {
        "ID": "over21",
        "Name": {
          "en": "Over 21",
          "nl": "Ouder dan 21"
        },
        "Description": {
          "en": "If you are over 21",
          "nl": "Of u ouder dan 21 bent"
        },
        "Index": 3,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.ageLimits.over65": {
        "ID": "over65",
        "Name": {
          "en": "Over 65",
          "nl": "Ouder dan 65"
        },
        "Description": {
          "en": "If you are over 65",
          "nl": "Of u ouder dan 65 bent"
        },
        "Index": 4,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.idin.address": {
        "ID": "address",
        "Name": {
          "en": "Address",
          "nl": "Adres"
        },
        "Description": {
          "en": "Your address, as registered at your bank",
          "nl": "Uw adres, zoals geregistreerd bij uw bank"
        },
        "Index": 4,
        "CredentialTypeID": "idin",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.idin.city": {
        "ID": "city",
        "Name": {
          "en": "City",
          "nl": "Stad"
        },
        "Description": {
          "en": "Your city of residence, as registered at your bank",
          "nl": "Uw stad, zoals geregistreerd bij uw bank"
        },
        "Index": 6,
        "CredentialTypeID": "idin",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.idin.country": {
        "ID": "country",
        "Name": {
          "en": "Country",
          "nl": "Land"
        },
        "Description": {
          "en": "Your country of residence, as registered at your bank",
          "nl": "Uw woonland, zoals geregistreerd bij uw bank"
        },
        "Index": 7,
        "CredentialTypeID": "idin",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.idin.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth, as registered at your bank",
          "nl": "Uw geboortedatum, zoals geregistreerd bij uw bank"
        },
        "Index": 2,
        "CredentialTypeID": "idin",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.idin.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your family name, as registered at your bank",
          "nl": "Uw achternaam, zoals geregistreerd bij uw bank"
        },
        "Index": 1,
        "CredentialTypeID": "idin",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.idin.gender": {
        "ID": "gender",
        "Name": {
          "en": "Gender",
          "nl": "Geslacht"
        },
        "Description": {
          "en": "Your gender, as registered at your bank",
          "nl": "Uw geslacht, zoals geregistreerd bij uw bank"
        },
        "Index": 3,
        "CredentialTypeID": "idin",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.idin.initials": {
        "ID": "initials",
        "Name": {
          "en": "Initials",
          "nl": "Initialen"
        },
        "Description": {
          "en": "First letters of your given name(s), as registered at your bank",
          "nl": "Uw initialen, zoals geregistreerd bij uw bank"
        },
        "Index": 0,
        "CredentialTypeID": "idin",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.idin.over12": {
        "ID": "over12",
        "Optional": "true",
        "Name": {
          "en": "Over 12",
          "nl": "Ouder dan 12"
        },
        "Description": {
          "en": "If you are over 12",
          "nl": "Of u ouder dan 12 bent"
        },
        "Index": 8,
        "CredentialTypeID": "idin",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.idin.over16": {
        "ID": "over16",
        "Optional": "true",
        "Name": {
          "en": "Over 16",
          "nl": "Ouder dan 16"
        },
        "Description": {
          "en": "If you are over 16",
          "nl": "Of u ouder dan 16 bent"
        },
        "Index": 9,
        "CredentialTypeID": "idin",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.idin.over18": {
        "ID": "over18",
        "Optional": "true",
        "Name": {
          "en": "Over 18",
          "nl": "Ouder dan 18"
        },
        "Description": {
          "en": "If you are over 18",
          "nl": "Of u ouder dan 18 bent"
        },
        "Index": 10,
        "CredentialTypeID": "idin",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.idin.over21": {
        "ID": "over21",
        "Optional": "true",
        "Name": {
          "en": "Over 21",
          "nl": "Ouder dan 21"
        },
        "Description": {
          "en": "If you are over 21",
          "nl": "Of u ouder dan 21 bent"
        },
        "Index": 11,
        "CredentialTypeID": "idin",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.idin.over65": {
        "ID": "over65",
        "Optional": "true",
        "Name": {
          "en": "Over 65",
          "nl": "Ouder dan 65"
        },
        "Description": {
          "en": "If you are over 65",
          "nl": "Of u ouder dan 65 bent"
        },
        "Index": 12,
        "CredentialTypeID": "idin",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.idin.idin.zipcode": {
        "ID": "zipcode",
        "Name": {
          "en": "Zip code",
          "nl": "Postcode"
        },
        "Description": {
          "en": "Your postal code, as registered at your bank",
          "nl": "Uw postcode, zoals geregistreerd bij uw bank"
        },
        "Index": 5,
        "CredentialTypeID": "idin",
        "IssuerID": "idin",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.irmages.photos.photo": {
        "ID": "photo",
        "Name": {
          "en": "Photo",
          "nl": "Foto"
        },
        "Description": {
          "en": "Your high quality portrait photo",
          "nl": "Uw pasfoto in hoge kwaliteit"
        },
        "Index": 0,
        "CredentialTypeID": "photos",
        "IssuerID": "irmages",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.ivido.login.identifier": {
        "ID": "identifier",
        "Name": {
          "en": "Identifier",
          "nl": "Identifier"
        },
        "Description": {
          "en": "Unique identifier for Ivido",
          "nl": "Unieke identifier voor Ivido"
        },
        "Index": 0,
        "CredentialTypeID": "login",
        "IssuerID": "ivido",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.kvk.official.authority": {
        "ID": "authority",
        "Name": {
          "en": "Authority",
          "nl": "Bevoegdheid"
        },
        "Description": {
          "en": "Authority",
          "nl": "Bevoegdheid"
        },
        "Index": 3,
        "CredentialTypeID": "official",
        "IssuerID": "kvk",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.kvk.official.fullname": {
        "ID": "fullname",
        "Name": {
          "en": "Full name of official",
          "nl": "Volledige naam functionaris"
        },
        "Description": {
          "en": "Full name of official",
          "nl": "Volledige naam functionaris"
        },
        "Index": 1,
        "CredentialTypeID": "official",
        "IssuerID": "kvk",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.kvk.official.kvkNumber": {
        "ID": "kvkNumber",
        "Name": {
          "en": "KVK number",
          "nl": "KVK nummer"
        },
        "Description": {
          "en": "KVK number",
          "nl": "KVK nummer"
        },
        "Index": 6,
        "CredentialTypeID": "official",
        "IssuerID": "kvk",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.kvk.official.legalEntity": {
        "ID": "legalEntity",
        "Name": {
          "en": "Legal entity",
          "nl": "Onderneming"
        },
        "Description": {
          "en": "Legal entity",
          "nl": "Onderneming"
        },
        "Index": 0,
        "CredentialTypeID": "official",
        "IssuerID": "kvk",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.kvk.official.officeAddress": {
        "ID": "officeAddress",
        "Name": {
          "en": "Registered office",
          "nl": "Vestiging"
        },
        "Description": {
          "en": "Registered office",
          "nl": "Vestiging"
        },
        "Index": 4,
        "CredentialTypeID": "official",
        "IssuerID": "kvk",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.kvk.official.officePhone": {
        "ID": "officePhone",
        "Name": {
          "en": "Phone",
          "nl": "Telefoon"
        },
        "Description": {
          "en": "Phone",
          "nl": "Telefoon"
        },
        "Index": 5,
        "CredentialTypeID": "official",
        "IssuerID": "kvk",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.kvk.official.position": {
        "ID": "position",
        "Name": {
          "en": "Position",
          "nl": "Functie"
        },
        "Description": {
          "en": "Position",
          "nl": "Functie"
        },
        "Index": 2,
        "CredentialTypeID": "official",
        "IssuerID": "kvk",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.kvk.official.sbiCode": {
        "ID": "sbiCode",
        "Name": {
          "en": "SBI code",
          "nl": "SBI code"
        },
        "Description": {
          "en": "SBI code",
          "nl": "SBI code"
        },
        "Index": 7,
        "CredentialTypeID": "official",
        "IssuerID": "kvk",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.maas.maasid.maasid": {
        "ID": "maasid",
        "Name": {
          "en": "MaaS ID",
          "nl": "MaaS ID"
        },
        "Description": {
          "en": "MaaS ID",
          "nl": "MaaS ID"
        },
        "Index": 0,
        "CredentialTypeID": "maasid",
        "IssuerID": "maas",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.address.city": {
        "ID": "city",
        "Name": {
          "en": "City",
          "nl": "Woonplaats"
        },
        "Description": {
          "en": "Your city of residence",
          "nl": "Uw woonplaats"
        },
        "Index": 4,
        "CredentialTypeID": "address",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.address.houseNumber": {
        "ID": "houseNumber",
        "Optional": "true",
        "Name": {
          "en": "House number",
          "nl": "Huisnummer"
        },
        "Description": {
          "en": "Your house number, letter and/or addition",
          "nl": "Uw huisnummer, letter en/of toevoeging"
        },
        "Index": 1,
        "CredentialTypeID": "address",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.address.municipality": {
        "ID": "municipality",
        "Name": {
          "en": "Municipality",
          "nl": "Gemeente"
        },
        "Description": {
          "en": "Your municipality",
          "nl": "Uw gemeente"
        },
        "Index": 3,
        "CredentialTypeID": "address",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.address.street": {
        "ID": "street",
        "Name": {
          "en": "Street",
          "nl": "Straat"
        },
        "Description": {
          "en": "Your street",
          "nl": "Uw straat"
        },
        "Index": 0,
        "CredentialTypeID": "address",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.address.zipcode": {
        "ID": "zipcode",
        "Name": {
          "en": "Zip code",
          "nl": "Postcode"
        },
        "Description": {
          "en": "Your zip code",
          "nl": "Uw postcode"
        },
        "Index": 2,
        "CredentialTypeID": "address",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.ageLimits.over12": {
        "ID": "over12",
        "Name": {
          "en": "Over 12",
          "nl": "Ouder dan 12"
        },
        "Description": {
          "en": "Whether you are over 12",
          "nl": "Of u ouder dan 12 bent"
        },
        "Index": 0,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.ageLimits.over16": {
        "ID": "over16",
        "Name": {
          "en": "Over 16",
          "nl": "Ouder dan 16"
        },
        "Description": {
          "en": "Whether you are over 16",
          "nl": "Of u ouder dan 16 bent"
        },
        "Index": 1,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.ageLimits.over18": {
        "ID": "over18",
        "Name": {
          "en": "Over 18",
          "nl": "Ouder dan 18"
        },
        "Description": {
          "en": "Whether you are over 18",
          "nl": "Of u ouder dan 18 bent"
        },
        "Index": 2,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.ageLimits.over21": {
        "ID": "over21",
        "Name": {
          "en": "Over 21",
          "nl": "Ouder dan 21"
        },
        "Description": {
          "en": "Whether you are over 21",
          "nl": "Of u ouder dan 21 bent"
        },
        "Index": 3,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.ageLimits.over65": {
        "ID": "over65",
        "Name": {
          "en": "Over 65",
          "nl": "Ouder dan 65"
        },
        "Description": {
          "en": "Whether you are over 65",
          "nl": "Of u ouder dan 65 bent"
        },
        "Index": 4,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.bsn.bsn": {
        "ID": "bsn",
        "Name": {
          "en": "BSN",
          "nl": "BSN"
        },
        "Description": {
          "en": "Your Dutch Citizen service number (BSN)",
          "nl": "Uw Burgerservicenummer (BSN)"
        },
        "Index": 0,
        "CredentialTypeID": "bsn",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.personalData.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth",
          "nl": "Uw geboortedatum"
        },
        "Index": 5,
        "DisplayIndex": 6,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.personalData.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Geslachtsnaam"
        },
        "Description": {
          "en": "Your family name, as given to you at birth",
          "nl": "Uw achternaam, zoals aan u toegekend bij uw geboorte"
        },
        "Index": 3,
        "DisplayIndex": 3,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.personalData.firstnames": {
        "ID": "firstnames",
        "Name": {
          "en": "First names",
          "nl": "Voornamen"
        },
        "Description": {
          "en": "Your first names",
          "nl": "Uw voornamen"
        },
        "Index": 1,
        "DisplayIndex": 1,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.personalData.fullname": {
        "ID": "fullname",
        "Optional": "true",
        "Name": {
          "en": "Full name",
          "nl": "Volledige naam"
        },
        "Description": {
          "en": "Your full name",
          "nl": "Uw volledige naam"
        },
        "Index": 4,
        "DisplayIndex": 5,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.personalData.gender": {
        "ID": "gender",
        "Name": {
          "en": "Gender",
          "nl": "Geslacht"
        },
        "Description": {
          "en": "Your gender",
          "nl": "Uw geslacht"
        },
        "Index": 6,
        "DisplayIndex": 7,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.personalData.initials": {
        "ID": "initials",
        "Name": {
          "en": "Initials",
          "nl": "Voorletters"
        },
        "Description": {
          "en": "Your initials, abbreviating your first names",
          "nl": "Uw voorletters, een afkorting van uw voornamen"
        },
        "Index": 0,
        "DisplayIndex": 0,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.personalData.nationality": {
        "ID": "nationality",
        "Optional": "true",
        "Name": {
          "en": "Dutch nationality",
          "nl": "Nederlandse nationaliteit"
        },
        "Description": {
          "en": "Whether you have the dutch nationality",
          "nl": "Of u de Nederlandse nationaliteit bezit"
        },
        "Index": 7,
        "DisplayIndex": 8,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.personalData.prefix": {
        "ID": "prefix",
        "Optional": "true",
        "Name": {
          "en": "Prefix",
          "nl": "Voorvoegsel"
        },
        "Description": {
          "en": "Prefix of your family name",
          "nl": "Voorvoegsel van uw achternaam"
        },
        "Index": 2,
        "DisplayIndex": 2,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.personalData.surname": {
        "ID": "surname",
        "Name": {
          "en": "Surname",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your full family name: your family name or (a combination with) that of your partner",
          "nl": "Uw volledige achternaam: uw geslachtsnaam of (een combinatie met) die van uw partner"
        },
        "Index": 8,
        "DisplayIndex": 4,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.travelDocument.documentissuer": {
        "ID": "documentissuer",
        "Optional": "true",
        "Name": {
          "en": "Document issuer",
          "nl": "Uitgever"
        },
        "Description": {
          "en": "Issuer of the travel document",
          "nl": "Autoriteit van afgifte reisdocument"
        },
        "Index": 4,
        "CredentialTypeID": "travelDocument",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.travelDocument.expirydate": {
        "ID": "expirydate",
        "Name": {
          "en": "Expiry date",
          "nl": "Verloopdatum"
        },
        "Description": {
          "en": "Expiry date of the travel document",
          "nl": "Verloopdatum van het reisdocument"
        },
        "Index": 3,
        "CredentialTypeID": "travelDocument",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.travelDocument.issuancedate": {
        "ID": "issuancedate",
        "Name": {
          "en": "Issuance date",
          "nl": "Datum uitgifte"
        },
        "Description": {
          "en": "Date of issuance of the travel document",
          "nl": "Datum van uitgifte van het reisdocument"
        },
        "Index": 2,
        "CredentialTypeID": "travelDocument",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.travelDocument.kind": {
        "ID": "kind",
        "Name": {
          "en": "Document kind",
          "nl": "Soort document"
        },
        "Description": {
          "en": "The document kind (passport or identity card)",
          "nl": "Het soort reisdocument (paspoort of identiteitskaart)"
        },
        "Index": 0,
        "CredentialTypeID": "travelDocument",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nijmegen.travelDocument.number": {
        "ID": "number",
        "Name": {
          "en": "Document number",
          "nl": "Documentnummer"
        },
        "Description": {
          "en": "The travel document number",
          "nl": "Het documentnummer"
        },
        "Index": 1,
        "CredentialTypeID": "travelDocument",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nuts.agb.agbcode": {
        "ID": "agbcode",
        "Name": {
          "en": "agbcode",
          "nl": "agbcode"
        },
        "Description": {
          "en": "uniquely identifying key for individual care providers and care organisations",
          "nl": "unieke identificerende sleutel van individuele zorgverleners en zorgorganisaties"
        },
        "Index": 0,
        "CredentialTypeID": "agb",
        "IssuerID": "nuts",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.nuts.agb.role": {
        "ID": "role",
        "Optional": "true",
        "Name": {
          "en": "role",
          "nl": "rol"
        },
        "Description": {
          "en": "care provider role related to the uniquely identifying key",
          "nl": "zorgverlenersrol met betrekking tot de unieke code"
        },
        "Index": 1,
        "CredentialTypeID": "agb",
        "IssuerID": "nuts",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.rdw.vrn.vrn": {
        "ID": "vrn",
        "Name": {
          "en": "Vehicle registration number",
          "nl": "Kentekennummer"
        },
        "Description": {
          "en": "The identifying numbers on the license plate of your vehicle.",
          "nl": "Het nummer op de kentekenplaat van uw voertuig."
        },
        "Index": 0,
        "CredentialTypeID": "vrn",
        "IssuerID": "rdw",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.surf.surfdrive.displayname": {
        "ID": "displayname",
        "Name": {
          "en": "Name",
          "nl": "Naam"
        },
        "Description": {
          "en": "Your name",
          "nl": "Uw naam"
        },
        "Index": 2,
        "CredentialTypeID": "surfdrive",
        "IssuerID": "surf",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.surf.surfdrive.emailadres": {
        "ID": "emailadres",
        "Name": {
          "en": "Email address",
          "nl": "E-mailadres"
        },
        "Description": {
          "en": "Your email address",
          "nl": "Uw e-mailadres"
        },
        "Index": 1,
        "CredentialTypeID": "surfdrive",
        "IssuerID": "surf",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.surf.surfdrive.eppn": {
        "ID": "eppn",
        "Name": {
          "en": "Institution user ID",
          "nl": "Instelling gebruikers-ID"
        },
        "Description": {
          "en": "Your ID at your institute",
          "nl": "Uw ID bij uw instelling"
        },
        "Index": 0,
        "CredentialTypeID": "surfdrive",
        "IssuerID": "surf",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.suwinet.income.income": {
        "ID": "income",
        "Name": {
          "en": "Income",
          "nl": "Inkomen"
        },
        "Description": {
          "en": "Income according to Suwinet",
          "nl": "Inkomen volgens Suwinet"
        },
        "Index": 0,
        "CredentialTypeID": "income",
        "IssuerID": "suwinet",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.vgz.machtiging.clientfullname": {
        "ID": "clientfullname",
        "Name": {
          "en": "Insured person",
          "nl": "Verzekerde"
        },
        "Description": {
          "en": "The name of the VGZ customer who mandated you",
          "nl": "De naam van de VGZ verzekerde die deze machtiging aan u gegevens heeft"
        },
        "Index": 1,
        "CredentialTypeID": "machtiging",
        "IssuerID": "vgz",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.vgz.machtiging.clientnumber": {
        "ID": "clientnumber",
        "Name": {
          "en": "VGZ Customer number",
          "nl": "VGZ Klantnummer"
        },
        "Description": {
          "en": "The VGZ customer number of the VGZ client who mandated you",
          "nl": "Het VGZ klantnummer van de VGZ verzekerde die deze machtiging aan u gegeven heeft"
        },
        "Index": 0,
        "CredentialTypeID": "machtiging",
        "IssuerID": "vgz",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.vgz.machtiging.mandateid": {
        "ID": "mandateid",
        "Name": {
          "en": "MandateID",
          "nl": "MachtigingID"
        },
        "Description": {
          "en": "A unique ID for this mandate",
          "nl": "Een uniek ID voor deze machtiging"
        },
        "Index": 2,
        "CredentialTypeID": "machtiging",
        "IssuerID": "vgz",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.vngrealisatie.fieldlabparticipant.edition": {
        "ID": "edition",
        "Name": {
          "en": "Edition",
          "nl": "Editie"
        },
        "Description": {
          "en": "The edition of the fieldlab",
          "nl": "De editie van het fieldlab"
        },
        "Index": 0,
        "CredentialTypeID": "fieldlabparticipant",
        "IssuerID": "vngrealisatie",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.vngrealisatie.fieldlabparticipant.participantid": {
        "ID": "participantid",
        "Name": {
          "en": "Participant ID",
          "nl": "Deelnemernummer"
        },
        "Description": {
          "en": "Uniquely identifying fieldlab participant identifier",
          "nl": "Uniek identificerend nummer voor een fieldlabdeelnemer"
        },
        "Index": 1,
        "CredentialTypeID": "fieldlabparticipant",
        "IssuerID": "vngrealisatie",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.vzvz.healthcareidentity.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth",
          "nl": "Uw geboortedatum"
        },
        "Index": 5,
        "CredentialTypeID": "healthcareidentity",
        "IssuerID": "vzvz",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.vzvz.healthcareidentity.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Geslachtsnaam"
        },
        "Description": {
          "en": "Your family name, as given to you at birth",
          "nl": "Uw achternaam, zoals aan u toegekend bij uw geboorte"
        },
        "Index": 4,
        "CredentialTypeID": "healthcareidentity",
        "IssuerID": "vzvz",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.vzvz.healthcareidentity.firstnames": {
        "ID": "firstnames",
        "Name": {
          "en": "First names",
          "nl": "Voornamen"
        },
        "Description": {
          "en": "Your first names",
          "nl": "Uw voornamen"
        },
        "Index": 2,
        "CredentialTypeID": "healthcareidentity",
        "IssuerID": "vzvz",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.vzvz.healthcareidentity.healthcarecode": {
        "ID": "healthcarecode",
        "Name": {
          "en": "Healthcare code",
          "nl": "Zorgcode"
        },
        "Description": {
          "en": "Your Dutch healthcare code, with which you can login online at Dutch healthcare institutions",
          "nl": "Uw zorgcode, waarmee u online bij zorginstellingen in kunt loggen"
        },
        "Index": 0,
        "CredentialTypeID": "healthcareidentity",
        "IssuerID": "vzvz",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.vzvz.healthcareidentity.initials": {
        "ID": "initials",
        "Name": {
          "en": "Initials",
          "nl": "Voorletters"
        },
        "Description": {
          "en": "Your initials, abbreviating your first names",
          "nl": "Uw voorletters, een afkorting van uw voornamen"
        },
        "Index": 1,
        "CredentialTypeID": "healthcareidentity",
        "IssuerID": "vzvz",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.vzvz.healthcareidentity.issuancemethod": {
        "ID": "issuancemethod",
        "Name": {
          "en": "Issuance method",
          "nl": "Uitgiftemethode"
        },
        "Description": {
          "en": "The way in which your healthcare identity was issued",
          "nl": "De wijze waarop uw zorgidentiteit is uitgegeven"
        },
        "Index": 6,
        "CredentialTypeID": "healthcareidentity",
        "IssuerID": "vzvz",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.vzvz.healthcareidentity.prefix": {
        "ID": "prefix",
        "Name": {
          "en": "Prefix",
          "nl": "Voorvoegsel"
        },
        "Description": {
          "en": "Prefix of your family name",
          "nl": "Voorvoegsel van uw achternaam"
        },
        "Index": 3,
        "CredentialTypeID": "healthcareidentity",
        "IssuerID": "vzvz",
        "SchemeManagerID": "irma-demo"
      },
      "irma-demo.wigo4it.stadspas.stadspas": {
        "ID": "stadspas",
        "Name": {
          "en": "City pass",
          "nl": "Stadspas"
        },
        "Description": {
          "en": "Indicator that a citizen is in posession of a digital city pass",
          "nl": "Indicatie dat een burger in het bezit is van een digitale stadspas"
        },
        "Index": 0,
        "CredentialTypeID": "stadspas",
        "IssuerID": "wigo4it",
        "SchemeManagerID": "irma-demo"
      },
      "pbdf.chipsoft.bsn.bsn": {
        "ID": "bsn",
        "Name": {
          "en": "BSN from healthcare",
          "nl": "BSN vanuit de zorg"
        },
        "Description": {
          "en": "Your Dutch Citizen service number (BSN) from healthcare",
          "nl": "Uw Burgerservicenummer (BSN) vanuit de zorg"
        },
        "Index": 0,
        "DisplayIndex": 0,
        "CredentialTypeID": "bsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.chipsoft.bsn.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth",
          "nl": "Uw geboortedatum"
        },
        "Index": 5,
        "DisplayIndex": 5,
        "CredentialTypeID": "bsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.chipsoft.bsn.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Geslachtsnaam"
        },
        "Description": {
          "en": "Your family name, as given to you at birth",
          "nl": "Uw achternaam, zoals aan u toegekend bij uw geboorte"
        },
        "Index": 4,
        "DisplayIndex": 4,
        "CredentialTypeID": "bsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.chipsoft.bsn.firstnames": {
        "ID": "firstnames",
        "Name": {
          "en": "First names",
          "nl": "Voornamen"
        },
        "Description": {
          "en": "Your first names",
          "nl": "Uw voornamen"
        },
        "Index": 2,
        "DisplayIndex": 2,
        "CredentialTypeID": "bsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.chipsoft.bsn.initials": {
        "ID": "initials",
        "Name": {
          "en": "Initials",
          "nl": "Voorletters"
        },
        "Description": {
          "en": "Your initials, abbreviating your first names",
          "nl": "Uw voorletters, een afkorting van uw voornamen"
        },
        "Index": 1,
        "DisplayIndex": 1,
        "CredentialTypeID": "bsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.chipsoft.bsn.prefix": {
        "ID": "prefix",
        "Optional": "true",
        "Name": {
          "en": "Prefix",
          "nl": "Voorvoegsel"
        },
        "Description": {
          "en": "Prefix of your family name",
          "nl": "Voorvoegsel van uw achternaam"
        },
        "Index": 3,
        "DisplayIndex": 3,
        "CredentialTypeID": "bsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.chipsoft.testbsn.bsn": {
        "ID": "bsn",
        "Name": {
          "en": "Test BSN from healthcare",
          "nl": "Test BSN vanuit de zorg"
        },
        "Description": {
          "en": "Test BSN from healthcare",
          "nl": "Test BSN vanuit de zorg"
        },
        "Index": 0,
        "DisplayIndex": 0,
        "CredentialTypeID": "testbsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.chipsoft.testbsn.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth",
          "nl": "Uw geboortedatum"
        },
        "Index": 5,
        "DisplayIndex": 5,
        "CredentialTypeID": "testbsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.chipsoft.testbsn.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Geslachtsnaam"
        },
        "Description": {
          "en": "Your family name, as given to you at birth",
          "nl": "Uw achternaam, zoals aan u toegekend bij uw geboorte"
        },
        "Index": 4,
        "DisplayIndex": 4,
        "CredentialTypeID": "testbsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.chipsoft.testbsn.firstnames": {
        "ID": "firstnames",
        "Name": {
          "en": "First names",
          "nl": "Voornamen"
        },
        "Description": {
          "en": "Your first names",
          "nl": "Uw voornamen"
        },
        "Index": 2,
        "DisplayIndex": 2,
        "CredentialTypeID": "testbsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.chipsoft.testbsn.initials": {
        "ID": "initials",
        "Name": {
          "en": "Initials",
          "nl": "Voorletters"
        },
        "Description": {
          "en": "Your initials, abbreviating your first names",
          "nl": "Uw voorletters, een afkorting van uw voornamen"
        },
        "Index": 1,
        "DisplayIndex": 1,
        "CredentialTypeID": "testbsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.chipsoft.testbsn.prefix": {
        "ID": "prefix",
        "Optional": "true",
        "Name": {
          "en": "Prefix",
          "nl": "Voorvoegsel"
        },
        "Description": {
          "en": "Prefix of your family name",
          "nl": "Voorvoegsel van uw achternaam"
        },
        "Index": 3,
        "DisplayIndex": 3,
        "CredentialTypeID": "testbsn",
        "IssuerID": "chipsoft",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gebiedonline.livingarea.city": {
        "ID": "city",
        "Name": {
          "en": "City",
          "nl": "Plaats"
        },
        "Description": {
          "en": "The city where I live",
          "nl": "De plaats waar ik woon"
        },
        "Index": 2,
        "CredentialTypeID": "livingarea",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gebiedonline.livingarea.district": {
        "ID": "district",
        "Name": {
          "en": "District",
          "nl": "Wijk"
        },
        "Description": {
          "en": "The district where I live",
          "nl": "De wijk waar ik woon"
        },
        "Index": 1,
        "CredentialTypeID": "livingarea",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gebiedonline.livingarea.zipcode": {
        "ID": "zipcode",
        "Name": {
          "en": "Zip code in 4 digits",
          "nl": "Postcode in 4 cijfers"
        },
        "Description": {
          "en": "Zip code (4 digits) of the area where I live",
          "nl": "Postcode (4 cijfers) van het gebied waar ik woon"
        },
        "Index": 0,
        "CredentialTypeID": "livingarea",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gebiedonline.useridentification.logincode": {
        "ID": "logincode",
        "Name": {
          "en": "Login code",
          "nl": "Logincode"
        },
        "Description": {
          "en": "My personal code to get access to my user account",
          "nl": "Mijn persoonlijke code om toegang te krijgen tot mijn gebruikersaccount"
        },
        "Index": 0,
        "CredentialTypeID": "useridentification",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gebiedonline.workingarea.city": {
        "ID": "city",
        "Name": {
          "en": "City",
          "nl": "Plaats"
        },
        "Description": {
          "en": "The city/cities where I work",
          "nl": "De plaats(en) waar ik werk"
        },
        "Index": 2,
        "CredentialTypeID": "workingarea",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gebiedonline.workingarea.district": {
        "ID": "district",
        "Name": {
          "en": "District",
          "nl": "Wijk"
        },
        "Description": {
          "en": "The district(s) where I work",
          "nl": "De wijk(en) waar ik werk"
        },
        "Index": 1,
        "CredentialTypeID": "workingarea",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gebiedonline.workingarea.zipcode": {
        "ID": "zipcode",
        "Name": {
          "en": "Zip code in 4 digits",
          "nl": "Postcode in 4 cijfers"
        },
        "Description": {
          "en": "Zip code (4 digits) of the area(s) where I work",
          "nl": "Postcode (4 cijfers) van de gebied(en) waar ik werk"
        },
        "Index": 0,
        "CredentialTypeID": "workingarea",
        "IssuerID": "gebiedonline",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.address.city": {
        "ID": "city",
        "Name": {
          "en": "City",
          "nl": "Woonplaats"
        },
        "Description": {
          "en": "Your city of residence",
          "nl": "Uw woonplaats"
        },
        "Index": 4,
        "CredentialTypeID": "address",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.address.houseNumber": {
        "ID": "houseNumber",
        "Optional": "true",
        "Name": {
          "en": "House number",
          "nl": "Huisnummer"
        },
        "Description": {
          "en": "Your house number, letter and/or addition",
          "nl": "Uw huisnummer, letter en/of toevoeging"
        },
        "Index": 1,
        "CredentialTypeID": "address",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.address.municipality": {
        "ID": "municipality",
        "Name": {
          "en": "Municipality",
          "nl": "Gemeente"
        },
        "Description": {
          "en": "Your municipality",
          "nl": "Uw gemeente"
        },
        "Index": 3,
        "CredentialTypeID": "address",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.address.street": {
        "ID": "street",
        "Name": {
          "en": "Street",
          "nl": "Straat"
        },
        "Description": {
          "en": "Your street",
          "nl": "Uw straat"
        },
        "Index": 0,
        "CredentialTypeID": "address",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.address.zipcode": {
        "ID": "zipcode",
        "Name": {
          "en": "Zip code",
          "nl": "Postcode"
        },
        "Description": {
          "en": "Your zip code",
          "nl": "Uw postcode"
        },
        "Index": 2,
        "CredentialTypeID": "address",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.bsn": {
        "ID": "bsn",
        "Name": {
          "en": "BSN",
          "nl": "BSN"
        },
        "Description": {
          "en": "Your Dutch Citizen service number (BSN)",
          "nl": "Uw Burgerservicenummer (BSN)"
        },
        "Index": 16,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.cityofbirth": {
        "ID": "cityofbirth",
        "Name": {
          "en": "City of birth",
          "nl": "Geboorteplaats"
        },
        "Description": {
          "en": "Your city of birth",
          "nl": "Uw geboorteplaats"
        },
        "Index": 9,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.countryofbirth": {
        "ID": "countryofbirth",
        "Name": {
          "en": "Country of birth",
          "nl": "Geboorteland"
        },
        "Description": {
          "en": "Your country of birth",
          "nl": "Uw geboorteland"
        },
        "Index": 10,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth",
          "nl": "Uw geboortedatum"
        },
        "Index": 8,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.digidlevel": {
        "ID": "digidlevel",
        "Name": {
          "en": "DigiD assurance level",
          "nl": "DigiD betrouwbaarheidsniveau"
        },
        "Description": {
          "en": "Het DigiD betrouwbaarheidsniveau waarmee uw identiteit is vastgesteld",
          "nl": "The DigiD assurance level with which your identity was verified"
        },
        "Index": 17,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Geslachtsnaam"
        },
        "Description": {
          "en": "Your family name, as given to you at birth",
          "nl": "Uw achternaam, zoals aan u toegekend bij uw geboorte"
        },
        "Index": 3,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.firstnames": {
        "ID": "firstnames",
        "Name": {
          "en": "First names",
          "nl": "Voornamen"
        },
        "Description": {
          "en": "Your first names",
          "nl": "Uw voornamen"
        },
        "Index": 1,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.fullname": {
        "ID": "fullname",
        "Optional": "true",
        "Name": {
          "en": "Full name",
          "nl": "Volledige naam"
        },
        "Description": {
          "en": "Your full name",
          "nl": "Uw volledige naam"
        },
        "Index": 4,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.gender": {
        "ID": "gender",
        "Name": {
          "en": "Gender",
          "nl": "Geslacht"
        },
        "Description": {
          "en": "Your gender",
          "nl": "Uw geslacht"
        },
        "Index": 5,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.initials": {
        "ID": "initials",
        "Name": {
          "en": "Initials",
          "nl": "Voorletters"
        },
        "Description": {
          "en": "Your initials, abbreviating your first names",
          "nl": "Uw voorletters, een afkorting van uw voornamen"
        },
        "Index": 0,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.nationality": {
        "ID": "nationality",
        "Optional": "true",
        "Name": {
          "en": "Dutch nationality",
          "nl": "Nederlandse nationaliteit"
        },
        "Description": {
          "en": "Whether you have the dutch nationality",
          "nl": "Of u de Nederlandse nationaliteit bezit"
        },
        "Index": 6,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.over12": {
        "ID": "over12",
        "Name": {
          "en": "Over 12",
          "nl": "Ouder dan 12"
        },
        "Description": {
          "en": "Whether you are over 12",
          "nl": "Of u ouder dan 12 bent"
        },
        "Index": 11,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.over16": {
        "ID": "over16",
        "Name": {
          "en": "Over 16",
          "nl": "Ouder dan 16"
        },
        "Description": {
          "en": "Whether you are over 16",
          "nl": "Of u ouder dan 16 bent"
        },
        "Index": 12,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.over18": {
        "ID": "over18",
        "Name": {
          "en": "Over 18",
          "nl": "Ouder dan 18"
        },
        "Description": {
          "en": "Whether you are over 18",
          "nl": "Of u ouder dan 18 bent"
        },
        "Index": 13,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.over21": {
        "ID": "over21",
        "Name": {
          "en": "Over 21",
          "nl": "Ouder dan 21"
        },
        "Description": {
          "en": "Whether you are over 21",
          "nl": "Of u ouder dan 21 bent"
        },
        "Index": 14,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.over65": {
        "ID": "over65",
        "Name": {
          "en": "Over 65",
          "nl": "Ouder dan 65"
        },
        "Description": {
          "en": "Whether you are over 65",
          "nl": "Of u ouder dan 65 bent"
        },
        "Index": 15,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.prefix": {
        "ID": "prefix",
        "Name": {
          "en": "Prefix",
          "nl": "Voorvoegsel"
        },
        "Description": {
          "en": "Prefix of your family name",
          "nl": "Voorvoegsel van uw achternaam"
        },
        "Index": 2,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.gemeente.personalData.surname": {
        "ID": "surname",
        "Name": {
          "en": "Surname",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your full family name: your family name or (a combination with) that of your partner",
          "nl": "Uw volledige achternaam: uw geslachtsnaam of (een combinatie met) die van uw partner"
        },
        "Index": 7,
        "CredentialTypeID": "personalData",
        "IssuerID": "gemeente",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.address.city": {
        "ID": "city",
        "Name": {
          "en": "City",
          "nl": "Woonplaats"
        },
        "Description": {
          "en": "Your city of residence",
          "nl": "Uw woonplaats"
        },
        "Index": 4,
        "CredentialTypeID": "address",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.address.houseNumber": {
        "ID": "houseNumber",
        "Optional": "true",
        "Name": {
          "en": "House number",
          "nl": "Huisnummer"
        },
        "Description": {
          "en": "Your house number, letter and/or addition",
          "nl": "Uw huisnummer, letter en/of toevoeging"
        },
        "Index": 1,
        "CredentialTypeID": "address",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.address.municipality": {
        "ID": "municipality",
        "Name": {
          "en": "Municipality",
          "nl": "Gemeente"
        },
        "Description": {
          "en": "Your municipality",
          "nl": "Uw gemeente"
        },
        "Index": 3,
        "CredentialTypeID": "address",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.address.street": {
        "ID": "street",
        "Name": {
          "en": "Street",
          "nl": "Straat"
        },
        "Description": {
          "en": "Your street",
          "nl": "Uw straat"
        },
        "Index": 0,
        "CredentialTypeID": "address",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.address.zipcode": {
        "ID": "zipcode",
        "Name": {
          "en": "Zip code",
          "nl": "Postcode"
        },
        "Description": {
          "en": "Your zip code",
          "nl": "Uw postcode"
        },
        "Index": 2,
        "CredentialTypeID": "address",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.ageLimits.over12": {
        "ID": "over12",
        "Name": {
          "en": "Over 12",
          "nl": "Ouder dan 12"
        },
        "Description": {
          "en": "Whether you are over 12",
          "nl": "Of u ouder dan 12 bent"
        },
        "Index": 0,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.ageLimits.over16": {
        "ID": "over16",
        "Name": {
          "en": "Over 16",
          "nl": "Ouder dan 16"
        },
        "Description": {
          "en": "Whether you are over 16",
          "nl": "Of u ouder dan 16 bent"
        },
        "Index": 1,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.ageLimits.over18": {
        "ID": "over18",
        "Name": {
          "en": "Over 18",
          "nl": "Ouder dan 18"
        },
        "Description": {
          "en": "Whether you are over 18",
          "nl": "Of u ouder dan 18 bent"
        },
        "Index": 2,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.ageLimits.over21": {
        "ID": "over21",
        "Name": {
          "en": "Over 21",
          "nl": "Ouder dan 21"
        },
        "Description": {
          "en": "Whether you are over 21",
          "nl": "Of u ouder dan 21 bent"
        },
        "Index": 3,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.ageLimits.over65": {
        "ID": "over65",
        "Name": {
          "en": "Over 65",
          "nl": "Ouder dan 65"
        },
        "Description": {
          "en": "Whether you are over 65",
          "nl": "Of u ouder dan 65 bent"
        },
        "Index": 4,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.bsn.bsn": {
        "ID": "bsn",
        "Name": {
          "en": "BSN",
          "nl": "BSN"
        },
        "Description": {
          "en": "Your Dutch Citizen service number (BSN)",
          "nl": "Uw Burgerservicenummer (BSN)"
        },
        "Index": 0,
        "CredentialTypeID": "bsn",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.personalData.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth",
          "nl": "Uw geboortedatum"
        },
        "Index": 6,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.personalData.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Geslachtsnaam"
        },
        "Description": {
          "en": "Your family name, as given to you at birth",
          "nl": "Uw achternaam, zoals aan u toegekend bij uw geboorte"
        },
        "Index": 3,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.personalData.firstnames": {
        "ID": "firstnames",
        "Name": {
          "en": "First names",
          "nl": "Voornamen"
        },
        "Description": {
          "en": "Your first names",
          "nl": "Uw voornamen"
        },
        "Index": 1,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.personalData.fullname": {
        "ID": "fullname",
        "Optional": "true",
        "Name": {
          "en": "Full name",
          "nl": "Volledige naam"
        },
        "Description": {
          "en": "Your full name",
          "nl": "Uw volledige naam"
        },
        "Index": 5,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.personalData.gender": {
        "ID": "gender",
        "Name": {
          "en": "Gender",
          "nl": "Geslacht"
        },
        "Description": {
          "en": "Your gender",
          "nl": "Uw geslacht"
        },
        "Index": 7,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.personalData.initials": {
        "ID": "initials",
        "Name": {
          "en": "Initials",
          "nl": "Voorletters"
        },
        "Description": {
          "en": "Your initials, abbreviating your first names",
          "nl": "Uw voorletters, een afkorting van uw voornamen"
        },
        "Index": 0,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.personalData.nationality": {
        "ID": "nationality",
        "Optional": "true",
        "Name": {
          "en": "Dutch nationality",
          "nl": "Nederlandse nationaliteit"
        },
        "Description": {
          "en": "Whether you have the dutch nationality",
          "nl": "Of u de Nederlandse nationaliteit bezit"
        },
        "Index": 8,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.personalData.prefix": {
        "ID": "prefix",
        "Optional": "true",
        "Name": {
          "en": "Prefix",
          "nl": "Voorvoegsel"
        },
        "Description": {
          "en": "Prefix of your family name",
          "nl": "Voorvoegsel van uw achternaam"
        },
        "Index": 2,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.personalData.surname": {
        "ID": "surname",
        "Name": {
          "en": "Surname",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your full family name: your family name or (a combination with) that of your partner",
          "nl": "Uw volledige achternaam: uw geslachtsnaam of (een combinatie met) die van uw partner"
        },
        "Index": 4,
        "CredentialTypeID": "personalData",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.travelDocument.documentissuer": {
        "ID": "documentissuer",
        "Optional": "true",
        "Name": {
          "en": "Document issuer",
          "nl": "Uitgever"
        },
        "Description": {
          "en": "Issuer of the travel document",
          "nl": "Autoriteit van afgifte reisdocument"
        },
        "Index": 4,
        "CredentialTypeID": "travelDocument",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.travelDocument.expirydate": {
        "ID": "expirydate",
        "Name": {
          "en": "Expiry date",
          "nl": "Verloopdatum"
        },
        "Description": {
          "en": "Expiry date of the travel document",
          "nl": "Verloopdatum van het reisdocument"
        },
        "Index": 3,
        "CredentialTypeID": "travelDocument",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.travelDocument.issuancedate": {
        "ID": "issuancedate",
        "Name": {
          "en": "Issuance date",
          "nl": "Datum uitgifte"
        },
        "Description": {
          "en": "Date of issuance of the travel document",
          "nl": "Datum van uitgifte van het reisdocument"
        },
        "Index": 2,
        "CredentialTypeID": "travelDocument",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.travelDocument.kind": {
        "ID": "kind",
        "Name": {
          "en": "Document kind",
          "nl": "Soort document"
        },
        "Description": {
          "en": "The document kind (passport or identity card)",
          "nl": "Het soort reisdocument (paspoort of identiteitskaart)"
        },
        "Index": 0,
        "CredentialTypeID": "travelDocument",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nijmegen.travelDocument.number": {
        "ID": "number",
        "Name": {
          "en": "Document number",
          "nl": "Documentnummer"
        },
        "Description": {
          "en": "The travel document number",
          "nl": "Het documentnummer"
        },
        "Index": 1,
        "CredentialTypeID": "travelDocument",
        "IssuerID": "nijmegen",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.nuts.agb.agbcode": {
        "ID": "agbcode",
        "Name": {
          "en": "AGB-code",
          "nl": "AGB-code"
        },
        "Description": {
          "en": "Uniquely identifying key for individual care providers and care organizations",
          "nl": "Uniek identificerende sleutel van individuele zorgverleners en zorgorganisaties"
        },
        "Index": 0,
        "CredentialTypeID": "agb",
        "IssuerID": "nuts",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.ageLimits.over12": {
        "ID": "over12",
        "Name": {
          "en": "Over 12",
          "nl": "Ouder dan 12"
        },
        "Description": {
          "en": "Whether you are over 12",
          "nl": "Of u ouder dan 12 bent"
        },
        "Index": 0,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.ageLimits.over16": {
        "ID": "over16",
        "Name": {
          "en": "Over 16",
          "nl": "Ouder dan 16"
        },
        "Description": {
          "en": "Whether you are over 16",
          "nl": "Of u ouder dan 16 bent"
        },
        "Index": 1,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.ageLimits.over18": {
        "ID": "over18",
        "Name": {
          "en": "Over 18",
          "nl": "Ouder dan 18"
        },
        "Description": {
          "en": "Whether you are over 18",
          "nl": "Of u ouder dan 18 bent"
        },
        "Index": 2,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.ageLimits.over21": {
        "ID": "over21",
        "Name": {
          "en": "Over 21",
          "nl": "Ouder dan 21"
        },
        "Description": {
          "en": "Whether you are over 21",
          "nl": "Of u ouder dan 21 bent"
        },
        "Index": 3,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.ageLimits.over65": {
        "ID": "over65",
        "Name": {
          "en": "Over 65",
          "nl": "Ouder dan 65"
        },
        "Description": {
          "en": "Whether you are over 65",
          "nl": "Of u ouder dan 65 bent"
        },
        "Index": 4,
        "CredentialTypeID": "ageLimits",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.big.bignumber": {
        "ID": "bignumber",
        "Name": {
          "en": "BIG number",
          "nl": "BIG nummer"
        },
        "Description": {
          "en": "Your BIG code",
          "nl": "Uw BIG-nummer"
        },
        "Index": 0,
        "CredentialTypeID": "big",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.big.profession": {
        "ID": "profession",
        "Name": {
          "en": "Profession",
          "nl": "Beroep"
        },
        "Description": {
          "en": "The profession you have",
          "nl": "Uw beroep"
        },
        "Index": 2,
        "CredentialTypeID": "big",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.big.specialism": {
        "ID": "specialism",
        "Name": {
          "en": "Specialism",
          "nl": "Specialisme"
        },
        "Description": {
          "en": "The specialty you have as part of your profession",
          "nl": "De specialisatie binnen uw beroep"
        },
        "Index": 3,
        "CredentialTypeID": "big",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.big.startdate": {
        "ID": "startdate",
        "Name": {
          "en": "Start date",
          "nl": "Startdatum"
        },
        "Description": {
          "en": "Start date of this registration",
          "nl": "Startdatum van uw registratie"
        },
        "Index": 1,
        "CredentialTypeID": "big",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.diploma.achieved": {
        "ID": "achieved",
        "Name": {
          "en": "Achieved in",
          "nl": "Behaald in"
        },
        "Description": {
          "en": "Month of achieving this diploma",
          "nl": "Maand waarin dit diploma behaald is"
        },
        "Index": 8,
        "CredentialTypeID": "diploma",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.diploma.city": {
        "ID": "city",
        "Name": {
          "en": "City",
          "nl": "Stad"
        },
        "Description": {
          "en": "The city of the institute where this degree has been achieved",
          "nl": "De stad van de instantie waar dit diploma behaald is"
        },
        "Index": 10,
        "CredentialTypeID": "diploma",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.diploma.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth from your diploma",
          "nl": "Uw geboortedatum uit uw diploma"
        },
        "Index": 3,
        "CredentialTypeID": "diploma",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.diploma.degree": {
        "ID": "degree",
        "Optional": "true",
        "Name": {
          "en": "Degree",
          "nl": "Opleiding"
        },
        "Description": {
          "en": "Type of education",
          "nl": "Soort opleiding"
        },
        "Index": 6,
        "CredentialTypeID": "diploma",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.diploma.education": {
        "ID": "education",
        "Name": {
          "en": "Education",
          "nl": "Opleiding"
        },
        "Description": {
          "en": "Completed education",
          "nl": "Voltooide opleiding"
        },
        "Index": 5,
        "CredentialTypeID": "diploma",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.diploma.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your family name from your diploma",
          "nl": "Uw achternaam uit uw diploma"
        },
        "Index": 2,
        "CredentialTypeID": "diploma",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.diploma.firstname": {
        "ID": "firstname",
        "Name": {
          "en": "First name",
          "nl": "Voornaam"
        },
        "Description": {
          "en": "Your first name from your diploma",
          "nl": "Uw voornaam uit uw diploma"
        },
        "Index": 0,
        "CredentialTypeID": "diploma",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.diploma.gender": {
        "ID": "gender",
        "Name": {
          "en": "Gender",
          "nl": "Geslacht"
        },
        "Description": {
          "en": "Your gender from your diploma",
          "nl": "Uw geslacht uit uw diploma"
        },
        "Index": 4,
        "CredentialTypeID": "diploma",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.diploma.institute": {
        "ID": "institute",
        "Name": {
          "en": "Institute",
          "nl": "Instituut"
        },
        "Description": {
          "en": "The institute where this degree has been achieved",
          "nl": "De instantie waar dit diploma behaald is"
        },
        "Index": 9,
        "CredentialTypeID": "diploma",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.diploma.prefix": {
        "ID": "prefix",
        "Optional": "true",
        "Name": {
          "en": "Prefix",
          "nl": "Tussenvoegsel"
        },
        "Description": {
          "en": "Your family name prefix from your diploma",
          "nl": "Uw tussenvoegsel uit uw diploma"
        },
        "Index": 1,
        "CredentialTypeID": "diploma",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.diploma.profile": {
        "ID": "profile",
        "Optional": "true",
        "Name": {
          "en": "Profile",
          "nl": "Profiel"
        },
        "Description": {
          "en": "Education profile",
          "nl": "Opleidingsprofiel"
        },
        "Index": 7,
        "CredentialTypeID": "diploma",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.email.domain": {
        "ID": "domain",
        "Optional": "true",
        "Name": {
          "en": "Email domain name",
          "nl": "E-mail domeinnaam"
        },
        "Description": {
          "en": "The domain name of your email address",
          "nl": "De domeinnaam van uw e-mailadres"
        },
        "Index": 1,
        "CredentialTypeID": "email",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.email.email": {
        "ID": "email",
        "Name": {
          "en": "Email address",
          "nl": "E-mailadres"
        },
        "Description": {
          "en": "Your verified email address",
          "nl": "Uw geverifieerde e-mailadres"
        },
        "Index": 0,
        "CredentialTypeID": "email",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.facebook.dateofbirth": {
        "ID": "dateofbirth",
        "Optional": "true",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth, as registered in Facebook",
          "nl": "Uw geboortedatum, zoals opgegeven bij Facebook"
        },
        "Index": 4,
        "CredentialTypeID": "facebook",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.facebook.email": {
        "ID": "email",
        "Name": {
          "en": "Email address",
          "nl": "E-mailadres"
        },
        "Description": {
          "en": "Your email address, as registered by Facebook",
          "nl": "Uw e-mailadres, zoals geregistreerd bij Facebook"
        },
        "Index": 3,
        "CredentialTypeID": "facebook",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.facebook.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your family name, as registered by Facebook",
          "nl": "Uw achternaam, zoals geregistreerd bij Facebook"
        },
        "Index": 2,
        "CredentialTypeID": "facebook",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.facebook.firstname": {
        "ID": "firstname",
        "Name": {
          "en": "First name",
          "nl": "Voornaam"
        },
        "Description": {
          "en": "Your first name, as registered by Facebook",
          "nl": "Uw voornaam, zoals geregistreerd bij Facebook"
        },
        "Index": 1,
        "CredentialTypeID": "facebook",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.facebook.fullname": {
        "ID": "fullname",
        "Name": {
          "en": "Full name",
          "nl": "Volledige naam"
        },
        "Description": {
          "en": "Your full name, as registered by Facebook",
          "nl": "Uw volledige naam, zoals geregistreerd bij Facebook"
        },
        "Index": 0,
        "CredentialTypeID": "facebook",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.ideal.bic": {
        "ID": "bic",
        "Name": {
          "en": "BIC",
          "nl": "BIC"
        },
        "Description": {
          "en": "The Bank Identifier Code of your bank",
          "nl": "De Bank Identifier Code van uw bank"
        },
        "Index": 2,
        "CredentialTypeID": "ideal",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.ideal.fullname": {
        "ID": "fullname",
        "Name": {
          "en": "Account holder",
          "nl": "Rekeninghouder"
        },
        "Description": {
          "en": "Your full name, as registered at your bank",
          "nl": "Uw volledige naam, zoals geregistreerd bij uw bank"
        },
        "Index": 0,
        "CredentialTypeID": "ideal",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.ideal.iban": {
        "ID": "iban",
        "Name": {
          "en": "IBAN",
          "nl": "IBAN"
        },
        "Description": {
          "en": "The IBAN of your bank account",
          "nl": "De IBAN van uw bankrekening"
        },
        "Index": 1,
        "CredentialTypeID": "ideal",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.idin.address": {
        "ID": "address",
        "Name": {
          "en": "Address",
          "nl": "Adres"
        },
        "Description": {
          "en": "Your address, as registered at your bank",
          "nl": "Uw adres, zoals geregistreerd bij uw bank"
        },
        "Index": 4,
        "CredentialTypeID": "idin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.idin.city": {
        "ID": "city",
        "Name": {
          "en": "City",
          "nl": "Stad"
        },
        "Description": {
          "en": "Your city of residence, as registered at your bank",
          "nl": "Uw stad, zoals geregistreerd bij uw bank"
        },
        "Index": 6,
        "CredentialTypeID": "idin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.idin.country": {
        "ID": "country",
        "Name": {
          "en": "Country",
          "nl": "Land"
        },
        "Description": {
          "en": "Your country of residence, as registered at your bank",
          "nl": "Uw woonland, zoals geregistreerd bij uw bank"
        },
        "Index": 7,
        "CredentialTypeID": "idin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.idin.dateofbirth": {
        "ID": "dateofbirth",
        "Name": {
          "en": "Date of birth",
          "nl": "Geboortedatum"
        },
        "Description": {
          "en": "Your date of birth, as registered at your bank",
          "nl": "Uw geboortedatum, zoals geregistreerd bij uw bank"
        },
        "Index": 2,
        "CredentialTypeID": "idin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.idin.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your family name, as registered at your bank",
          "nl": "Uw achternaam, zoals geregistreerd bij uw bank"
        },
        "Index": 1,
        "CredentialTypeID": "idin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.idin.gender": {
        "ID": "gender",
        "Name": {
          "en": "Gender",
          "nl": "Geslacht"
        },
        "Description": {
          "en": "Your gender, as registered at your bank",
          "nl": "Uw geslacht, zoals geregistreerd bij uw bank"
        },
        "Index": 3,
        "CredentialTypeID": "idin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.idin.initials": {
        "ID": "initials",
        "Name": {
          "en": "Initials",
          "nl": "Initialen"
        },
        "Description": {
          "en": "First letters of your given name(s), as registered at your bank",
          "nl": "Uw initialen, zoals geregistreerd bij uw bank"
        },
        "Index": 0,
        "CredentialTypeID": "idin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.idin.over12": {
        "ID": "over12",
        "Optional": "true",
        "Name": {
          "en": "Over 12",
          "nl": "Ouder dan 12"
        },
        "Description": {
          "en": "If you are over 12",
          "nl": "Of u ouder dan 12 bent"
        },
        "Index": 8,
        "CredentialTypeID": "idin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.idin.over16": {
        "ID": "over16",
        "Optional": "true",
        "Name": {
          "en": "Over 16",
          "nl": "Ouder dan 16"
        },
        "Description": {
          "en": "If you are over 16",
          "nl": "Of u ouder dan 16 bent"
        },
        "Index": 9,
        "CredentialTypeID": "idin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.idin.over18": {
        "ID": "over18",
        "Optional": "true",
        "Name": {
          "en": "Over 18",
          "nl": "Ouder dan 18"
        },
        "Description": {
          "en": "If you are over 18",
          "nl": "Of u ouder dan 18 bent"
        },
        "Index": 10,
        "CredentialTypeID": "idin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.idin.over21": {
        "ID": "over21",
        "Optional": "true",
        "Name": {
          "en": "Over 21",
          "nl": "Ouder dan 21"
        },
        "Description": {
          "en": "If you are over 21",
          "nl": "Of u ouder dan 21 bent"
        },
        "Index": 11,
        "CredentialTypeID": "idin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.idin.over65": {
        "ID": "over65",
        "Optional": "true",
        "Name": {
          "en": "Over 65",
          "nl": "Ouder dan 65"
        },
        "Description": {
          "en": "If you are over 65",
          "nl": "Of u ouder dan 65 bent"
        },
        "Index": 12,
        "CredentialTypeID": "idin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.idin.zipcode": {
        "ID": "zipcode",
        "Name": {
          "en": "Zip code",
          "nl": "Postcode"
        },
        "Description": {
          "en": "Your postal code, as registered at your bank",
          "nl": "Uw postcode, zoals geregistreerd bij uw bank"
        },
        "Index": 5,
        "CredentialTypeID": "idin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.irmatube.id": {
        "ID": "id",
        "Name": {
          "en": "ID",
          "nl": "ID"
        },
        "Description": {
          "en": "Your membership ID",
          "nl": "Uw lidmaatschapsnummer"
        },
        "Index": 1,
        "CredentialTypeID": "irmatube",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.irmatube.type": {
        "ID": "type",
        "Name": {
          "en": "Type",
          "nl": "Type"
        },
        "Description": {
          "en": "Your membership type",
          "nl": "Uw lidmaatschapstype"
        },
        "Index": 0,
        "CredentialTypeID": "irmatube",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.linkedin.email": {
        "ID": "email",
        "Name": {
          "en": "Email address",
          "nl": "E-mailadres"
        },
        "Description": {
          "en": "Your email address, as registered by LinkedIn",
          "nl": "Uw e-mailadres, zoals geregistreerd bij LinkedIn"
        },
        "Index": 3,
        "CredentialTypeID": "linkedin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.linkedin.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your family name, as registered by LinkedIn",
          "nl": "Uw achternaam, zoals geregistreerd bij LinkedIn"
        },
        "Index": 2,
        "CredentialTypeID": "linkedin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.linkedin.firstname": {
        "ID": "firstname",
        "Name": {
          "en": "First name",
          "nl": "Voornaam"
        },
        "Description": {
          "en": "Your first name, as registered by LinkedIn",
          "nl": "Uw voornaam, zoals geregistreerd bij LinkedIn"
        },
        "Index": 1,
        "CredentialTypeID": "linkedin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.linkedin.fullname": {
        "ID": "fullname",
        "Name": {
          "en": "Full name",
          "nl": "Volledige naam"
        },
        "Description": {
          "en": "Your full name, as registered by LinkedIn",
          "nl": "Uw volledige naam, zoals geregistreerd bij LinkedIn"
        },
        "Index": 0,
        "CredentialTypeID": "linkedin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.linkedin.profileurl": {
        "ID": "profileurl",
        "Name": {
          "en": "Profile",
          "nl": "Profiel"
        },
        "Description": {
          "en": "URL to your LinkedIn profile",
          "nl": "URL naar uw LinkedIn-profiel"
        },
        "Index": 4,
        "CredentialTypeID": "linkedin",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.mijnirma.email": {
        "ID": "email",
        "Name": {
          "en": "Username",
          "nl": "Gebruikersnaam"
        },
        "Description": {
          "en": "Your MyIRMA username",
          "nl": "Uw MijnIRMA-gebruikersnaam"
        },
        "Index": 0,
        "CredentialTypeID": "mijnirma",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.mobilenumber.mobilenumber": {
        "ID": "mobilenumber",
        "Name": {
          "en": "Phone number",
          "nl": "Telefoonnummer"
        },
        "Description": {
          "en": "Your verified mobile phone number",
          "nl": "Uw geverifieerde mobiel telefoonnummer"
        },
        "Index": 0,
        "CredentialTypeID": "mobilenumber",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet-2.email": {
        "ID": "email",
        "Optional": "true",
        "Name": {
          "en": "Email address",
          "nl": "E-mailadres"
        },
        "Description": {
          "en": "Your email address at your institute",
          "nl": "Uw e-mailadres bij uw instantie"
        },
        "Index": 7,
        "CredentialTypeID": "surfnet-2",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet-2.familyname": {
        "ID": "familyname",
        "Optional": "true",
        "Name": {
          "en": "Family name",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your family name, as registered by your institute",
          "nl": "Uw achternaam, zoals geregistreerd bij uw instantie"
        },
        "Index": 6,
        "CredentialTypeID": "surfnet-2",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet-2.firstname": {
        "ID": "firstname",
        "Optional": "true",
        "Name": {
          "en": "First name",
          "nl": "Voornaam"
        },
        "Description": {
          "en": "Your first name, as registered by your institute",
          "nl": "Uw voornaam, zoals geregistreerd bij uw instantie"
        },
        "Index": 5,
        "CredentialTypeID": "surfnet-2",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet-2.fullid": {
        "ID": "fullid",
        "Optional": "true",
        "Name": {
          "en": "Full ID",
          "nl": "Volledig ID"
        },
        "Description": {
          "en": "Your full ID number at your institute",
          "nl": "Uw volledig ID-nummer bij uw instantie"
        },
        "Index": 3,
        "CredentialTypeID": "surfnet-2",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet-2.fullname": {
        "ID": "fullname",
        "Optional": "true",
        "Name": {
          "en": "Full name",
          "nl": "Volledige naam"
        },
        "Description": {
          "en": "Your full name, as registered by your institute",
          "nl": "Uw volledige naam, zoals geregistreerd bij uw instantie"
        },
        "Index": 4,
        "CredentialTypeID": "surfnet-2",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet-2.id": {
        "ID": "id",
        "Optional": "true",
        "Name": {
          "en": "User ID",
          "nl": "Gebruiker ID"
        },
        "Description": {
          "en": "Your ID number at your institute",
          "nl": "Uw ID-nummer bij uw instantie"
        },
        "Index": 2,
        "CredentialTypeID": "surfnet-2",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet-2.institute": {
        "ID": "institute",
        "Optional": "true",
        "Name": {
          "en": "Institute",
          "nl": "Instituut"
        },
        "Description": {
          "en": "The institute that provided these attributes",
          "nl": "De instantie die deze attributen heeft aangeleverd"
        },
        "Index": 0,
        "CredentialTypeID": "surfnet-2",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet-2.type": {
        "ID": "type",
        "Optional": "true",
        "Name": {
          "en": "Type",
          "nl": "Type"
        },
        "Description": {
          "en": "Your position at your institute",
          "nl": "Uw positie bij uw instantie"
        },
        "Index": 1,
        "CredentialTypeID": "surfnet-2",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet.email": {
        "ID": "email",
        "Name": {
          "en": "Email address",
          "nl": "E-mailadres"
        },
        "Description": {
          "en": "Your email address at your institute",
          "nl": "Uw e-mailadres bij uw instantie"
        },
        "Index": 6,
        "CredentialTypeID": "surfnet",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet.familyname": {
        "ID": "familyname",
        "Name": {
          "en": "Family name",
          "nl": "Achternaam"
        },
        "Description": {
          "en": "Your family name, as registered by your institute",
          "nl": "Uw achternaam, zoals geregistreerd bij uw instantie"
        },
        "Index": 5,
        "CredentialTypeID": "surfnet",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet.firstname": {
        "ID": "firstname",
        "Name": {
          "en": "First name",
          "nl": "Voornaam"
        },
        "Description": {
          "en": "Your first name, as registered by your institute",
          "nl": "Uw voornaam, zoals geregistreerd bij uw instantie"
        },
        "Index": 4,
        "CredentialTypeID": "surfnet",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet.fullname": {
        "ID": "fullname",
        "Name": {
          "en": "Full name",
          "nl": "Volledige naam"
        },
        "Description": {
          "en": "Your full name, as registered by your institute",
          "nl": "Uw volledige naam, zoals geregistreerd bij uw instantie"
        },
        "Index": 3,
        "CredentialTypeID": "surfnet",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet.id": {
        "ID": "id",
        "Name": {
          "en": "Institute ID",
          "nl": "Instituut ID"
        },
        "Description": {
          "en": "Your ID number at your institute",
          "nl": "Uw ID-nummer bij uw instantie"
        },
        "Index": 2,
        "CredentialTypeID": "surfnet",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet.institute": {
        "ID": "institute",
        "Name": {
          "en": "Institute",
          "nl": "Instituut"
        },
        "Description": {
          "en": "The institute that provided these attributes",
          "nl": "De instantie die deze attributen heeft aangeleverd"
        },
        "Index": 0,
        "CredentialTypeID": "surfnet",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.surfnet.type": {
        "ID": "type",
        "Name": {
          "en": "Type",
          "nl": "Type"
        },
        "Description": {
          "en": "Your position at your institute",
          "nl": "Uw positie bij uw instantie"
        },
        "Index": 1,
        "CredentialTypeID": "surfnet",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.twitter.email": {
        "ID": "email",
        "Name": {
          "en": "Email address",
          "nl": "E-mailadres"
        },
        "Description": {
          "en": "Your email address, as registered by Twitter",
          "nl": "Uw e-mailadres, zoals geregistreerd bij Twitter"
        },
        "Index": 2,
        "CredentialTypeID": "twitter",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.twitter.fullname": {
        "ID": "fullname",
        "Name": {
          "en": "Full name",
          "nl": "Volledige naam"
        },
        "Description": {
          "en": "Your full name, as registered by Twitter",
          "nl": "Uw volledige naam, zoals geregistreerd bij Twitter"
        },
        "Index": 1,
        "CredentialTypeID": "twitter",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.twitter.profileurl": {
        "ID": "profileurl",
        "Name": {
          "en": "Profile",
          "nl": "Profiel"
        },
        "Description": {
          "en": "URL to your Twitter profile",
          "nl": "URL naar uw Twitter-profiel"
        },
        "Index": 3,
        "CredentialTypeID": "twitter",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.pbdf.twitter.username": {
        "ID": "username",
        "Name": {
          "en": "Username",
          "nl": "Gebruikersnaam"
        },
        "Description": {
          "en": "Your username at Twitter, as registered by Twitter",
          "nl": "Uw gebruikersnaam bij Twitter, zoals geregistreerd bij Twitter"
        },
        "Index": 0,
        "CredentialTypeID": "twitter",
        "IssuerID": "pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.sidn-pbdf.irma.pseudonym": {
        "ID": "pseudonym",
        "Name": {
          "en": "Username",
          "nl": "Gebruikersnaam"
        },
        "Description": {
          "en": "Your MyIRMA username",
          "nl": "Uw MijnIRMA-gebruikersnaam"
        },
        "Index": 0,
        "CredentialTypeID": "irma",
        "IssuerID": "sidn-pbdf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.surf.secureid.environment": {
        "ID": "environment",
        "Optional": "true",
        "Name": {
          "en": "Environment",
          "nl": "Omgeving"
        },
        "Description": {
          "en": "The SURFsecureID environment",
          "nl": "De SURFsecureID-omgeving"
        },
        "Index": 1,
        "CredentialTypeID": "secureid",
        "IssuerID": "surf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.surf.secureid.secureid": {
        "ID": "secureid",
        "Name": {
          "en": "Identifier",
          "nl": "Identifier"
        },
        "Description": {
          "en": "Your SURFsecureID identifier",
          "nl": "Uw SURFsecureID identifier"
        },
        "Index": 0,
        "CredentialTypeID": "secureid",
        "IssuerID": "surf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.surf.surfdrive.displayname": {
        "ID": "displayname",
        "Name": {
          "en": "Name",
          "nl": "Naam"
        },
        "Description": {
          "en": "Your name",
          "nl": "Uw naam"
        },
        "Index": 2,
        "CredentialTypeID": "surfdrive",
        "IssuerID": "surf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.surf.surfdrive.emailadres": {
        "ID": "emailadres",
        "Name": {
          "en": "Email address",
          "nl": "E-mailadres"
        },
        "Description": {
          "en": "Your email address",
          "nl": "Uw e-mailadres"
        },
        "Index": 1,
        "CredentialTypeID": "surfdrive",
        "IssuerID": "surf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.surf.surfdrive.eppn": {
        "ID": "eppn",
        "Name": {
          "en": "Institution user ID",
          "nl": "Instelling gebruikers-ID"
        },
        "Description": {
          "en": "Your ID at your institute",
          "nl": "Uw ID bij uw instelling"
        },
        "Index": 0,
        "CredentialTypeID": "surfdrive",
        "IssuerID": "surf",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.vgz.machtiging.clientfullname": {
        "ID": "clientfullname",
        "Name": {
          "en": "Insured person",
          "nl": "Verzekerde"
        },
        "Description": {
          "en": "The name of the VGZ customer who mandated you",
          "nl": "De naam van de VGZ verzekerde die deze machtiging aan u gegevens heeft"
        },
        "Index": 1,
        "CredentialTypeID": "machtiging",
        "IssuerID": "vgz",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.vgz.machtiging.clientnumber": {
        "ID": "clientnumber",
        "Name": {
          "en": "VGZ Customer number",
          "nl": "VGZ Klantnummer"
        },
        "Description": {
          "en": "The VGZ customer number of the VGZ client who mandated you",
          "nl": "Het VGZ klantnummer van de VGZ verzekerde die deze machtiging aan u gegeven heeft"
        },
        "Index": 0,
        "CredentialTypeID": "machtiging",
        "IssuerID": "vgz",
        "SchemeManagerID": "pbdf"
      },
      "pbdf.vgz.machtiging.mandateid": {
        "ID": "mandateid",
        "Name": {
          "en": "MandateID",
          "nl": "MachtigingID"
        },
        "Description": {
          "en": "A unique ID for this mandate",
          "nl": "Een uniek ID voor deze machtiging"
        },
        "Index": 2,
        "CredentialTypeID": "machtiging",
        "IssuerID": "vgz",
        "SchemeManagerID": "pbdf"
      }
    },
    "Path": "/tmp/v2/irma_configuration",
    "DisabledSchemeManagers": {}
  }
}
""";
