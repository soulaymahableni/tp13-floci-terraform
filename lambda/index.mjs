// Fonction Lambda TP13 : invocation directe ou déclenchement par SQS.
export const handler = async (event) => {
  // Déclenchement par la file SQS (défi aws_lambda_event_source_mapping)
  if (Array.isArray(event?.Records)) {
    for (const record of event.Records) {
      console.log("Message SQS reçu :", record.body);
    }
    return { batchItemFailures: [] };
  }

  // Invocation directe : aws lambda invoke --payload '{"name":"Ada"}'
  const name = event?.name ?? "monde";
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: `Bonjour ${name} depuis Floci !`,
      at: new Date().toISOString(),
    }),
  };
};
