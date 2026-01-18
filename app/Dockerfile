FROM public.ecr.aws/lambda/python:3.11
COPY scanner.py ${LAMBDA_TASK_ROOT}
CMD [ "scanner.lambda_handler" ]