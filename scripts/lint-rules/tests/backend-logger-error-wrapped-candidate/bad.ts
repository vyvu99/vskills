try {
  doWork();
} catch (err) {
  logger.error({ error: err }, 'Failed to do work');
}
