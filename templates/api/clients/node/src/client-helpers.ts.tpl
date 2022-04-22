import * as grpc from '@grpc/grpc-js';
import { {{ title .Config.Name }}Client } from './grpc/{{ .Config.Name }}_grpc_pb';
import { createAuthenticationInterceptor, createErrorLoggerInterceptor } from '@outreach/grpc-client';
import winston from 'winston';
import * as find from '@outreach/find';

const level = 'error';
const ConsoleTransport = () => {
  return new winston.transports.Console({
    level
  });
};

/**
 * The ClientOptions interface defines the gRPC service endpoint the {{ title .Config.Name }}Client connects to as well
 * as any gRPC options that should be used by the client.
 */
export interface ClientOptions {
  /** This is the endpoint the client should connect to. If not specified a default is used. */
  endpoint?: string;

  /** This is the gRPC interceptors that should be run on messages passed through the client. */
  interceptors?: grpc.Interceptor[];
}

/**
 * @param accessToken The token to use to authenticate all requests the client submits
 * @param options The client options that affect its behavior
 * @returns The newly created {{ title .Config.Name }}Client instance
 */
export function create{{ title .Config.Name }}Client(accessToken: string, options?: ClientOptions): {{ title .Config.Name }}Client {
  const logger = winston.createLogger({ transports: [ConsoleTransport()] });
  const endpoint = options?.endpoint || find.service('{{ .Config.Name }}').dnsName + ':5000';
  const clientName = '{{ .Config.Name }}' + ':gRPCClient';
  logger.info(`${clientName}: Endpoint information: ${endpoint}`);
  const interceptors = [createAuthenticationInterceptor(accessToken), createErrorLoggerInterceptor(logger, endpoint)];
  if (options?.interceptors) {
    interceptors.push(...options.interceptors);
  }

  return new {{ title .Config.Name }}Client(endpoint, grpc.credentials.createInsecure(), { interceptors });
}
