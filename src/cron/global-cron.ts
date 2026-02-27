import type { CronService } from "./service.js";

let _cronService: CronService | null = null;

export function registerGlobalCron(service: CronService): void {
  _cronService = service;
}

export function getGlobalCron(): CronService | null {
  return _cronService;
}
