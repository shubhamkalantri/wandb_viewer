class AppConstants {
  static const String wandbGraphqlUrl = 'https://api.wandb.ai/graphql';
  static const Duration defaultPollInterval = Duration(seconds: 30);
  static const int defaultHistorySamples = 300;
  static const int defaultPageSize = 50;
  static const String apiKeyStorageKey = 'wandb_api_key';
}
