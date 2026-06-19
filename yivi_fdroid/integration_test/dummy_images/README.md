# Test Images

This directory contains fake image files used by the integration tests.

The images are fake, AI generated images of non existing persons. They do not represent real people.

These files are only used within the integration tests and should not be used anywhere else in the application.

## Source

The images were generated using:

- https://this-person-does-not-exist.com/en
- https://this-person-does-not-exist.com/en/download-page?image=genb50144acc0c31a3281991347def26b85
- https://this-person-does-not-exist.com/en/download-page?image=gen5286f0751632aa2cae58627e6686270f

The download links may stop working over time. The committed image files should be treated as the actual test fixtures. The links are included only as background information about where the images came from.

## Notes

- The images are fake, AI generated images of non existing persons.
- These files are only intended for use in integration tests.
- Do not replace or modify these files unless the related integration tests are updated accordingly.
- If new fake images are added, make sure they are committed together with the test cases that depend on them.

## Usage

The integration tests reference these files directly as fixtures. They should remain small, deterministic, and independent of external services.
