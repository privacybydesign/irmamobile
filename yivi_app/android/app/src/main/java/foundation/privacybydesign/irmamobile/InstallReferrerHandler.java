package foundation.privacybydesign.irmamobile;

import android.content.Context;
import android.os.RemoteException;

import androidx.annotation.NonNull;

import com.android.installreferrer.api.InstallReferrerClient;
import com.android.installreferrer.api.InstallReferrerStateListener;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Hands the Google Play install referrer to Dart. Replies with the referrer
 * string, or null when it cannot be read (not installed from Play, no Play
 * Store, or the API is unavailable).
 */
class InstallReferrerHandler implements MethodChannel.MethodCallHandler {
  static final String CHANNEL = "foundation.privacybydesign.irmamobile/install_referrer";

  private final Context context;

  InstallReferrerHandler(Context context) {
    this.context = context;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    if (!call.method.equals("getInstallReferrer")) {
      result.notImplemented();
      return;
    }

    InstallReferrerClient client = InstallReferrerClient.newBuilder(context).build();
    try {
      client.startConnection(new ReferrerListener(client, result));
    } catch (RuntimeException e) {
      result.success(null);
    }
  }

  private static class ReferrerListener implements InstallReferrerStateListener {
    private final InstallReferrerClient client;
    private final MethodChannel.Result result;
    private boolean replied = false;

    ReferrerListener(InstallReferrerClient client, MethodChannel.Result result) {
      this.client = client;
      this.result = result;
    }

    @Override
    public void onInstallReferrerSetupFinished(int responseCode) {
      String referrer = null;
      if (responseCode == InstallReferrerClient.InstallReferrerResponse.OK) {
        try {
          referrer = client.getInstallReferrer().getInstallReferrer();
        } catch (RemoteException | RuntimeException e) {
          referrer = null;
        }
      }

      client.endConnection();
      reply(referrer);
    }

    @Override
    public void onInstallReferrerServiceDisconnected() {
      reply(null);
    }

    private void reply(String referrer) {
      if (replied) {
        return;
      }
      replied = true;
      result.success(referrer);
    }
  }
}
