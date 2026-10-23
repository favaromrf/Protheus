import { provideRouter } from '@angular/router';
import { routes } from './app.routes';

import { APP_INITIALIZER, ApplicationConfig, importProvidersFrom } from '@angular/core';
import { provideHttpClient } from '@angular/common/http';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { PoHttpRequestModule } from '@po-ui/ng-components';
import { AppConfigService } from './service/app-config.service'; // Ajuste o caminho se necessário

// Função que obriga o Angular a aguardar o carregamento do JSON antes de iniciar a aplicação
function initializeApp(appConfigService: AppConfigService) {
  return () => appConfigService.loadConfig();
}

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(),
    importProvidersFrom([BrowserAnimationsModule, PoHttpRequestModule]),
    { provide: "Window", useValue: window },
    // Adicionamos o inicializador aqui:
    {
      provide: APP_INITIALIZER,
      useFactory: initializeApp,
      deps: [AppConfigService],
      multi: true
    }
  ],
};