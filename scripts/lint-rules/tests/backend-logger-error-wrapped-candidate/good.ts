try {
  doWork();
} catch (err) {
  logger.error(err, 'Failed to do work');
}
