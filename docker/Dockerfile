FROM androidsdk/android-31
WORKDIR /root
RUN sdkmanager --update
RUN sdkmanager --install "build-tools;33.0.2" "cmdline-tools;latest" "ndk;21.4.7075529" "platform-tools" "cmake;3.6.4111459"
RUN apt-get update && apt-get -y install zip libglu1-mesa chromium-browser clang cmake ninja-build pkg-config libgtk-3-dev
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.7.3-stable.tar.xz
RUN tar xf flutter_linux_3.7.3-stable.tar.xz
RUN echo 'export CHROME_EXECUTABLE="/usr/bin/chromium-browser"' >> .bashrc
RUN echo 'export PATH="$PATH:`pwd`/flutter/bin"' >> .bashrc
RUN git clone --recursive https://github.com/privacybydesign/irmamobile.git
CMD bash
