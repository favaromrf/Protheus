import { Routes } from '@angular/router';
import { AboutComponent } from './components/about/about.component';
import { SellerManagementComponent } from './components/seller-management/seller-management.component';

export const routes: Routes = [
    {path: 'Vendedor',   title: 'Vendedores',     component: SellerManagementComponent},
    {path: 'about',      title: 'Sobre o Projeto',     component: AboutComponent},
];
