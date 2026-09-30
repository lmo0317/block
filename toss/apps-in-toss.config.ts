import { defineConfig } from '@apps-in-toss/web-framework/config';

// The app type (game) is chosen in the Apps in Toss console; appName must match the console.
export default defineConfig({
  appName: 'puzzleblock',
  brand: { primaryColor: '#3385FF' },
  permissions: [],
  webView: {
    bounces: false,
    pullToRefreshEnabled: false,
    overScrollMode: 'never',
    allowsBackForwardNavigationGestures: false,
    mediaPlaybackRequiresUserAction: false,
  },
  // Game bar: transparent, only the "more" and X buttons
  navigationBar: { transparentBackground: true, withBackButton: false, withHomeButton: false, withTitle: false },
  webBundleDir: 'dist',
});
