import { Component, OnInit, ViewChild, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { take } from 'rxjs';
import { 
  PoModule, 
  PoTableColumn, 
  PoTableAction, 
  PoNotificationService, 
  PoModalComponent, 
  PoSelectOption 
} from '@po-ui/ng-components';
import { SellerService } from '../../service/seller.service';
import { Seller } from '../../interface/seller.model';
import { MunicipioService } from '../../service/municipio.service';
import { ComissoesService, VendedorComissao, ItemComissao } from '../../service/comissoes.service';
import { ComissaoService } from '../../service/comissao.service';

@Component({
  selector: 'app-seller-management',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, PoModule],
  templateUrl: './seller-management.component.html',
  styleUrls: ['./seller-management.component.css']
})
export class SellerManagementComponent implements OnInit {
  private sellerService = inject(SellerService);
  private comissoesService = inject(ComissoesService);
  private comissaoGridService = inject(ComissaoService);
  private poNotification = inject(PoNotificationService);
  private fb = inject(FormBuilder);
  private municipioService = inject(MunicipioService);

  @ViewChild('sellerModal', { static: true }) sellerModal!: PoModalComponent;
  @ViewChild('viewSellerModal', { static: true }) viewSellerModal!: PoModalComponent;
  @ViewChild('copyModal', { static: true }) copyModal!: PoModalComponent;
  @ViewChild('comissaoTabelaModal', { static: true }) comissaoTabelaModal!: PoModalComponent;

  sellers = signal<Seller[]>([]);
  isEditing = false;
  isEditingComissao = false;

  vendedorComissoesDados: VendedorComissao | null = null;
  codigoVendedorAtual: string = '';

  // Listas das abas ativas
  itemsTabelaGrpProduto: any[] = [];   // SBM
  itemsTabelaAcy: any[] = [];          // ACY (Grupo de Clientes)
  itemsTabelaAcn: any[] = [];          // ACN (Regra por Negócio)

  isLoadingTabelaComissao: boolean = false;
  abaTabelaAtiva: string = 'SBM';
  itemTabelaEmEdicao: any = null;
  isIncluindoTabela: boolean = false;

  // Formulário para edição/inclusão por item nas tabelas de comissão
  comissaoTabelaForm: FormGroup = this.fb.group({
    codigoChave: ['', Validators.required],
    descricao: ['', Validators.required],
    comis1: [0, [Validators.required, Validators.min(0)]],
    comis2: [0, [Validators.required, Validators.min(0)]],
    comis3: [0, [Validators.required, Validators.min(0)]],
    comis4: [0, [Validators.required, Validators.min(0)]]
  });

  tableAcoesLinha: PoTableAction[] = [
    {
      label: 'Editar Comissões',
      icon: 'po-icon po-icon-edit',
      action: (row: any) => this.prepararEdicaoTabelaItem(row)
    }
  ];

  columnsTabelaGrpProduto: PoTableColumn[] = [
    { property: 'BM_GRUPO', label: 'Grupo de Produto', width: '20%' },
    { property: 'BM_DESC', label: 'Descrição', width: '35%' },
    { property: 'BM_COMIS1', label: 'Comissão 1 (%)', type: 'number', width: '11%' },
    { property: 'BM_COMIS2', label: 'Comissão 2 (%)', type: 'number', width: '11%' },
    { property: 'BM_COMIS3', label: 'Comissão 3 (%)', type: 'number', width: '11%' },
    { property: 'BM_COMIS4', label: 'Comissão 4 (%)', type: 'number', width: '12%' }
  ];

  columnsTabelaAcy: PoTableColumn[] = [
    { property: 'ACY_GRPVEN', label: 'Grupo de Clientes', width: '25%' },
    { property: 'ACY_DESCRI', label: 'Descrição', width: '35%' },
    { property: 'ACY_COMIS1', label: 'Comissão 1 (%)', type: 'number', width: '10%' },
    { property: 'ACY_COMIS2', label: 'Comissão 2 (%)', type: 'number', width: '10%' },
    { property: 'ACY_COMIS3', label: 'Comissão 3 (%)', type: 'number', width: '10%' },
    { property: 'ACY_COMIS4', label: 'Comissão 4 (%)', type: 'number', width: '10%' }
  ];

  columnsTabelaAcn: PoTableColumn[] = [
    { property: 'ACN_GRPVEN', label: 'Regra por Negócio', width: '25%' },
    { property: 'ACN_DESCRI', label: 'Descrição', width: '35%' },
    { property: 'ACN_COMIS1', label: 'Comissão 1 (%)', type: 'number', width: '10%' },
    { property: 'ACN_COMIS2', label: 'Comissão 2 (%)', type: 'number', width: '10%' },
    { property: 'ACN_COMIS3', label: 'Comissão 3 (%)', type: 'number', width: '10%' },
    { property: 'ACN_COMIS4', label: 'Comissão 4 (%)', type: 'number', width: '10%' }
  ];

  filterValue = '';
  filterSignal = signal<string>('');
  currentPage = signal<number>(1);
  pageSize = 5;

  statesList: PoSelectOption[] = [
    { label: 'AC - Acre', value: 'AC' }, { label: 'AL - Alagoas', value: 'AL' },
    { label: 'AP - Amapá', value: 'AP' }, { label: 'AM - Amazonas', value: 'AM' },
    { label: 'BA - Bahia', value: 'BA' }, { label: 'CE - Ceará', value: 'CE' },
    { label: 'DF - Distrito Federal', value: 'DF' }, { label: 'ES - Espírito Santo', value: 'ES' },
    { label: 'GO - Goiás', value: 'GO' }, { label: 'MA - Maranhão', value: 'MA' },
    { label: 'MT - Mato Grosso', value: 'MT' }, { label: 'MS - Mato Grosso do Sul', value: 'MS' },
    { label: 'MG - Minas Gerais', value: 'MG' }, { label: 'PA - Pará', value: 'PA' },
    { label: 'PB - Paraíba', value: 'PB' }, { label: 'PR - Paraná', value: 'PR' },
    { label: 'PE - Pernambuco', value: 'PE' }, { label: 'PI - Piauí', value: 'PI' },
    { label: 'RJ - Rio de Janeiro', value: 'RJ' }, { label: 'RN - Rio Grande do Norte', value: 'RN' },
    { label: 'RS - Rio Grande do Sul', value: 'RS' }, { label: 'RO - Rondônia', value: 'RO' },
    { label: 'RR - Roraima', value: 'RR' }, { label: 'SC - Santa Catarina', value: 'SC' },
    { label: 'SP - São Paulo', value: 'SP' }, { label: 'SE - Sergipe', value: 'SE' },
    { label: 'TO - Tocantins', value: 'TO' }
  ];

  cidadesList: PoSelectOption[] = [];
  supervisoresList: PoSelectOption[] = [];
  targetSellersList: PoSelectOption[] = [];

  filteredSellers = computed(() => {
    const search = this.filterSignal().toLowerCase().trim();
    const list = this.sellers();
    if (!search) return list;
    return list.filter(item => {
      return Object.values(item).some(val => {
        if (val === null || val === undefined) return false;
        const actualVal = typeof val === 'object' && 'valor' in val ? val.valor : val;
        return actualVal?.toString().toLowerCase().includes(search);
      });
    });
  });

  totalFilteredItems = computed(() => this.filteredSellers().length);
  totalPages = computed(() => Math.ceil(this.totalFilteredItems() / this.pageSize));

  paginatedSellers = computed(() => {
    const items = this.filteredSellers();
    const page = this.currentPage();
    const start = (page - 1) * this.pageSize;
    return items.slice(start, start + this.pageSize);
  });

  rangeStart = computed(() => this.totalFilteredItems() === 0 ? 0 : (this.currentPage() - 1) * this.pageSize + 1);
  rangeEnd = computed(() => {
    const end = this.currentPage() * this.pageSize;
    return end > this.totalFilteredItems() ? this.totalFilteredItems() : end;
  });

  columns: PoTableColumn[] = [
    { property: 'code', label: 'Código', width: '10%' },
    { property: 'name', label: 'Nome', width: '40%' },
    { property: 'personalIdentification', label: 'CNPJ/CPF', width: '20%' },
    { 
      property: 'active', 
      label: 'Status', 
      width: '15%',
      type: 'label',
      labels: [
        { value: '2', color: 'color-10', label: 'Ativo' },
        { value: '1', color: 'color-07', label: 'Bloqueado' }
      ]
    }
  ];

  tableActions: PoTableAction[] = [
    { action: (row: Seller) => this.openModalForEdit(row), icon: 'po-icon-edit', label: 'Alterar Vendedor' },
    { action: (row: Seller) => this.openModalForCopy(row), icon: 'po-icon-copy', label: 'Copiar Perfil'  },
    { action: (row: Seller) => this.openViewModal(row), icon: 'po-icon-finance', label: 'Ajustar Comissões' },
    { action: (row: Seller) => this.openComissaoTabelaModal(row), icon: 'po-icon-grid', label: 'Tabela de Comissões' }
  ];

  sellerForm: FormGroup = this.fb.group({
    A3_FILIAL: [{ value: '01', disabled: true }],
    A3_COD: ['', [Validators.required, Validators.maxLength(6)]],
    A3_NOME: ['', [Validators.required, Validators.maxLength(40)]],
    A3_NREDUZ: [''],
    A3_END: [''],
    A3_BAIRRO: [''],
    A3_MUN: [''],
    A3_EST: ['SP'],
    A3_CEP: [''],
    A3_DDDTEL: [''],
    A3_MSBLQL: ['2'],
    A3_TEL: [''],
    A3_FAX: [''],
    A3_TELEX: [''],
    A3_TIPO: ['I'],
    A3_CGC: ['', [Validators.required]],
    A3_INSCR: [''],
    A3_INSCRM: [''],
    A3_EMAIL: [''],
    A3_HPAGE: [''],
    A3_CODUSR: [''],
    A3_SUPER: [''],
    A3_GEREN: [''],
    A3_FORNECE: [''],
    A3_LOJA: [''],
    A3_GERASE2: ['N'],
    A3_BCO1: [''],
    A3_REGIAO: [''],
    A3_COMIS: [0],
    A3_ALEMISS: [0],
    A3_ALBAIXA: [0],
    A3_ICM: [''],
    A3_ICMSRET: [''],
    A3_UNIDAD: [''],
    A3_ISS: [''],
    A3_IPI: [''],
    A3_REGSLA: [''],
    A3_QTCONTA: [0],
    A3_GRPREP: [''],
    A3_FRETE: [''],
    A3_ACREFIN: ['N'],
    A3_DIA: [15],
    A3_DDD: ['F'],
    A3_CARGO: [''],
    A3_PERDESC: [0],
    A3_TIPSUP: [''],
    A3_DIARESE: [0],
    A3_SENHA: [''],
    A3_PEDINI: [''],
    A3_PEDFIM: [''],
    A3_CLIINI: [''],
    A3_CLIFIM: [''],
    A3_PROXPED: [''],
    A3_PROXCLI: [''],
    A3_SINCTAF: ['S'],
    A3_FAT_RH: [''],
    A3_SINCAGE: ['S'],
    A3_GRUPSAN: [''],
    A3_SINCCON: ['S'],
    A3_DEPEND: [''],
    A3_PERAGE: ['A'],
    A3_PEN_ALI: [0],
    A3_PERTAF: ['A'],
    A3_TIPVEND: ['1'],
    A3_TIMEMIN: ['30'],
    A3_NUMRA: [''],
    A3_URLEXG: [''],
    A3_USUCORP: [''],
    A3_PAIS: ['105'],
    A3_HABSINC: [''],
    A3_DDI: [''],
    A3_CEL: [''],
    A3_NVLSTR: [''],
    A3_NIVEL: [0],
    A3_LANEXG: [''],
    A3_PISCOF: [''],
    A3_EMACORP: [''],
    A3_BIAGEND: ['2'],
    A3_BITAREF: ['2'],
    A3_BICONT: ['2'],
    A3_CODISS: [''],
    A3_MSEXP: [''],
    A3_HREXPO: [''],
    A3_BASEIR: ['1'],
    A3_HRUMOV: [''],
    A3_DTUMOV: [''],
    A3_FILFUN: [''],
    A3_HAND: ['2'],
    A3_SNAEXG: [''],
    A3_MODTRF: ['3'],
    A3_COMIS2: [0],
    A3_COMIS3: [0]
  });

  viewSellerForm: FormGroup = this.fb.group({
    code: [{ value: '', disabled: true }],
    name: [{ value: '', disabled: true }]
  });

  comissaoForm: FormGroup = this.fb.group({
    ZZA_DESCV: [''],
    ZZA_CODP: ['', [Validators.required]],
    ZZA_DESCP: ['', [Validators.required]],
    ZZA_COMIS: [0, [Validators.required]]
  });

  copyProfileForm: FormGroup = this.fb.group({
    sourceCode: [{ value: '', disabled: true }],
    sourceName: [{ value: '', disabled: true }],
    targetSellerCode: ['', [Validators.required]]
  });

  ngOnInit(): void {
    this.loadSellers();

    this.sellerForm.get('A3_EST')?.valueChanges.subscribe((estadoSigla) => {
      const siglaVal = typeof estadoSigla === 'object' && estadoSigla !== null && 'valor' in estadoSigla ? (estadoSigla as any).valor : estadoSigla;
      if (siglaVal) {
        this.carregarMunicipios(siglaVal);
      } else {
        this.cidadesList = [];
        this.sellerForm.get('A3_MUN')?.setValue('');
      }
    });

    const estadoInicial = this.sellerForm.get('A3_EST')?.value;
    if (estadoInicial) this.carregarMunicipios(estadoInicial);
  }

  carregarMunicipios(estado: string): void {
    this.municipioService.getMunicipios(estado).subscribe({
      next: (response) => {
        this.cidadesList = response.municipios.map(item => ({ label: item.municipio, value: item.municipio }));
      },
      error: () => {
        this.poNotification.error('Erro ao carregar a lista de municípios.');
        this.cidadesList = [];
      }
    });
  }

  atualizarListaSupervisores(codigoAtual: string = ''): void {
    this.supervisoresList = this.sellers()
      .filter(s => {
        const cod = s.A3_COD?.valor || s.code;
        return cod !== codigoAtual;
      })
      .map(s => {
        const cod = s.A3_COD?.valor || s.code;
        const nome = s.A3_NOME?.valor || s.name;
        return { label: `${cod} - ${nome}`, value: cod };
      });
  }

  loadSellers(): void {
    this.sellerService.getSellers().subscribe({
      next: (response) => {
        if (response && response.items) {
          const mapped = response.items.map(item => ({
            ...item,
            code: item.A3_COD?.valor || '',
            name: item.A3_NOME?.valor || '',
            personalIdentification: item.A3_CGC?.valor || '',
            active: item.A3_MSBLQL?.valor || '2'
          }));
          this.sellers.set(mapped);
        }
      },
      error: () => this.poNotification.error('Erro ao carregar a lista de vendedores.')
    });
  }

  onFilterChange(event: string): void {
    this.filterSignal.set(event);
    this.currentPage.set(1);
  }

  goToFirstPage(): void { this.currentPage.set(1); }
  goToPreviousPage(): void { if (this.currentPage() > 1) this.currentPage.update(p => p - 1); }
  goToNextPage(): void { if (this.currentPage() < this.totalPages()) this.currentPage.update(p => p + 1); }
  goToLastPage(): void { this.currentPage.set(this.totalPages()); }

  openViewModal(seller: Seller): void {
    const code = seller.A3_COD?.valor || seller.code;
    const name = seller.A3_NOME?.valor || seller.name;

    this.codigoVendedorAtual = code;
    this.viewSellerForm.patchValue({ code, name });
    
    this.resetarFormComissao(name);
    this.carregarComissoesVendedor(code);

    this.viewSellerModal.open();
  }

  openComissaoTabelaModal(seller: Seller): void {
    const code = seller.A3_COD?.valor || seller.code;
    this.codigoVendedorAtual = code;
    this.isLoadingTabelaComissao = true;
    this.itemTabelaEmEdicao = null;
    this.isIncluindoTabela = false;
    this.comissaoTabelaForm.reset();
    this.comissaoTabelaModal.open();

    // 1. Carregar SBM (Grupos de Produtos) filtrando vazios
    this.comissaoGridService.getDadosTabela('SBM').pipe(take(1)).subscribe({
      next: (response: any) => {
        let itensBrutos = [];
        if (Array.isArray(response)) {
          itensBrutos = response;
        } else if (response && Array.isArray(response.itens)) {
          itensBrutos = response.itens;
        } else if (response && Array.isArray(response.objects)) {
          itensBrutos = response.objects;
        } else if (response) {
          itensBrutos = [response];
        }

        this.itemsTabelaGrpProduto = itensBrutos
          .map((item: any) => ({
            ...item,
            BM_GRUPO: item.BM_GRUPO?.valor !== undefined ? item.BM_GRUPO.valor : (item.BM_GRUPO || ''),
            BM_DESC: item.BM_DESC?.valor !== undefined ? item.BM_DESC.valor : (item.BM_DESC || ''),
            BM_COMIS1: item.BM_COMIS1?.valor !== undefined ? Number(item.BM_COMIS1.valor) : Number(item.BM_COMIS1 || 0),
            BM_COMIS2: item.BM_COMIS2?.valor !== undefined ? Number(item.BM_COMIS2.valor) : Number(item.BM_COMIS2 || 0),
            BM_COMIS3: item.BM_COMIS3?.valor !== undefined ? Number(item.BM_COMIS3.valor) : Number(item.BM_COMIS3 || 0),
            BM_COMIS4: item.BM_COMIS4?.valor !== undefined ? Number(item.BM_COMIS4.valor) : Number(item.BM_COMIS4 || 0),
          }))
          .filter((item: any) => item.BM_GRUPO && item.BM_GRUPO.toString().trim() !== '');
      },
      error: () => this.poNotification.error('Erro ao carregar tabela SBM.')
    });

    // 2. Carregar ACY (Grupo de Clientes) filtrando vazios no campo ACY_GRPVEN
    this.comissaoGridService.getDadosTabela('ACY').pipe(take(1)).subscribe({
      next: (response: any) => { 
        let itensBrutos = [];
        if (Array.isArray(response)) {
          itensBrutos = response;
        } else if (response && Array.isArray(response.itens)) {
          itensBrutos = response.itens;
        } else if (response && Array.isArray(response.objects)) {
          itensBrutos = response.objects;
        } else if (response) {
          itensBrutos = [response];
        }

        this.itemsTabelaAcy = itensBrutos
          .map((item: any) => ({
            ...item,
            ACY_GRPVEN: item.ACY_GRPVEN?.valor !== undefined ? item.ACY_GRPVEN.valor : (item.ACY_GRPVEN || ''),
            ACY_DESCRI: item.ACY_DESCRI?.valor !== undefined ? item.ACY_DESCRI.valor : (item.ACY_DESCRI || ''),
            ACY_COMIS1: item.ACY_COMIS1?.valor !== undefined ? Number(item.ACY_COMIS1.valor) : Number(item.ACY_COMIS1 || 0),
            ACY_COMIS2: item.ACY_COMIS2?.valor !== undefined ? Number(item.ACY_COMIS2.valor) : Number(item.ACY_COMIS2 || 0),
            ACY_COMIS3: item.ACY_COMIS3?.valor !== undefined ? Number(item.ACY_COMIS3.valor) : Number(item.ACY_COMIS3 || 0),
            ACY_COMIS4: item.ACY_COMIS4?.valor !== undefined ? Number(item.ACY_COMIS4.valor) : Number(item.ACY_COMIS4 || 0),
          }))
          .filter((item: any) => item.ACY_GRPVEN && item.ACY_GRPVEN.toString().trim() !== '');
      },
      error: () => this.poNotification.error('Erro ao carregar tabela ACY.')
    });

    // 3. Carregar ACN (Regra por Negócio) filtrando vazios no campo ACN_GRPVEN
    this.comissaoGridService.getDadosTabela('ACN').pipe(take(1)).subscribe({
      next: (response: any) => { 
        let itensBrutos = [];
        if (Array.isArray(response)) {
          itensBrutos = response;
        } else if (response && Array.isArray(response.itens)) {
          itensBrutos = response.itens;
        } else if (response && Array.isArray(response.objects)) {
          itensBrutos = response.objects;
        } else if (response) {
          itensBrutos = [response];
        }

        this.itemsTabelaAcn = itensBrutos
          .map((item: any) => ({
            ...item,
            ACN_GRPVEN: item.ACN_GRPVEN?.valor !== undefined ? item.ACN_GRPVEN.valor : (item.ACN_GRPVEN || ''),
            ACN_DESCRI: item.ACN_DESCRI?.valor !== undefined ? item.ACN_DESCRI.valor : (item.ACN_DESCRI || ''),
            ACN_COMIS1: item.ACN_COMIS1?.valor !== undefined ? Number(item.ACN_COMIS1.valor) : Number(item.ACN_COMIS1 || 0),
            ACN_COMIS2: item.ACN_COMIS2?.valor !== undefined ? Number(item.ACN_COMIS2.valor) : Number(item.ACN_COMIS2 || 0),
            ACN_COMIS3: item.ACN_COMIS3?.valor !== undefined ? Number(item.ACN_COMIS3.valor) : Number(item.ACN_COMIS3 || 0),
            ACN_COMIS4: item.ACN_COMIS4?.valor !== undefined ? Number(item.ACN_COMIS4.valor) : Number(item.ACN_COMIS4 || 0),
          }))
          .filter((item: any) => item.ACN_GRPVEN && item.ACN_GRPVEN.toString().trim() !== '');

        this.isLoadingTabelaComissao = false;
      },
      error: () => {
        this.poNotification.error('Erro ao carregar tabela ACN.');
        this.isLoadingTabelaComissao = false;
      }
    });
  }

  mudarAbaTabela(aba: string): void {
    this.abaTabelaAtiva = aba;
    this.itemTabelaEmEdicao = null;
    this.isIncluindoTabela = false;
    this.comissaoTabelaForm.reset();
  }

  prepararInclusaoTabela(aba: string): void {
    this.abaTabelaAtiva = aba;
    this.isIncluindoTabela = true;
    this.itemTabelaEmEdicao = {}; 
    
    this.comissaoTabelaForm.reset({
      codigoChave: '',
      descricao: '',
      comis1: 0,
      comis2: 0,
      comis3: 0,
      comis4: 0
    });
  }

  prepararEdicaoTabelaItem(row: any): void {
    this.isIncluindoTabela = false;
    this.itemTabelaEmEdicao = row;
    let codigo = '';
    let descricao = '';
    let c1 = 0, c2 = 0, c3 = 0, c4 = 0;

    if (this.abaTabelaAtiva === 'SBM') {
      codigo = row.BM_GRUPO;
      descricao = row.BM_DESC || '';
      c1 = row.BM_COMIS1 || 0; c2 = row.BM_COMIS2 || 0; c3 = row.BM_COMIS3 || 0; c4 = row.BM_COMIS4 || 0;
    } else if (this.abaTabelaAtiva === 'ACY') {
      codigo = row.ACY_GRPVEN;
      descricao = row.ACY_DESCRI || '';
      c1 = row.ACY_COMIS1 || 0; c2 = row.ACY_COMIS2 || 0; c3 = row.ACY_COMIS3 || 0; c4 = row.ACY_COMIS4 || 0;
    } else if (this.abaTabelaAtiva === 'ACN') {
      codigo = row.ACN_GRPVEN;
      descricao = row.ACN_DESCRI || '';
      c1 = row.ACN_COMIS1 || 0; c2 = row.ACN_COMIS2 || 0; c3 = row.ACN_COMIS3 || 0; c4 = row.ACN_COMIS4 || 0;
    }

    this.comissaoTabelaForm.patchValue({
      codigoChave: codigo,
      descricao: descricao,
      comis1: c1,
      comis2: c2,
      comis3: c3,
      comis4: c4
    });
  }

  salvarEdicaoTabelaItem(): void {
    if (this.comissaoTabelaForm.invalid) return;
    const values = this.comissaoTabelaForm.getRawValue();

    if (this.isIncluindoTabela) {
      let novoItem: any = {};
      if (this.abaTabelaAtiva === 'SBM') {
        novoItem = { BM_GRUPO: values.codigoChave, BM_DESC: values.descricao, BM_COMIS1: Number(values.comis1), BM_COMIS2: Number(values.comis2), BM_COMIS3: Number(values.comis3), BM_COMIS4: Number(values.comis4) };
        this.itemsTabelaGrpProduto.unshift(novoItem);
      } else if (this.abaTabelaAtiva === 'ACY') {
        novoItem = { ACY_GRPVEN: values.codigoChave, ACY_DESCRI: values.descricao, ACY_COMIS1: Number(values.comis1), ACY_COMIS2: Number(values.comis2), ACY_COMIS3: Number(values.comis3), ACY_COMIS4: Number(values.comis4) };
        this.itemsTabelaAcy.unshift(novoItem);
      } else if (this.abaTabelaAtiva === 'ACN') {
        novoItem = { ACN_GRPVEN: values.codigoChave, ACN_DESCRI: values.descricao, ACN_COMIS1: Number(values.comis1), ACN_COMIS2: Number(values.comis2), ACN_COMIS3: Number(values.comis3), ACN_COMIS4: Number(values.comis4) };
        this.itemsTabelaAcn.unshift(novoItem);
      }
      this.poNotification.success('Novo registro incluído com sucesso!');
    } else {
      if (this.abaTabelaAtiva === 'SBM') {
        this.itemTabelaEmEdicao.BM_COMIS1 = Number(values.comis1);
        this.itemTabelaEmEdicao.BM_COMIS2 = Number(values.comis2);
        this.itemTabelaEmEdicao.BM_COMIS3 = Number(values.comis3);
        this.itemTabelaEmEdicao.BM_COMIS4 = Number(values.comis4);
      } else if (this.abaTabelaAtiva === 'ACY') {
        this.itemTabelaEmEdicao.ACY_COMIS1 = Number(values.comis1);
        this.itemTabelaEmEdicao.ACY_COMIS2 = Number(values.comis2);
        this.itemTabelaEmEdicao.ACY_COMIS3 = Number(values.comis3);
        this.itemTabelaEmEdicao.ACY_COMIS4 = Number(values.comis4);
      } else if (this.abaTabelaAtiva === 'ACN') {
        this.itemTabelaEmEdicao.ACN_COMIS1 = Number(values.comis1);
        this.itemTabelaEmEdicao.ACN_COMIS2 = Number(values.comis2);
        this.itemTabelaEmEdicao.ACN_COMIS3 = Number(values.comis3);
        this.itemTabelaEmEdicao.ACN_COMIS4 = Number(values.comis4);
      }
      this.poNotification.success('Comissão atualizada com sucesso!');
    }

    this.itemTabelaEmEdicao = null;
    this.isIncluindoTabela = false;
    this.comissaoTabelaForm.reset();
  }

  cancelarEdicaoTabelaItem(): void {
    this.itemTabelaEmEdicao = null;
    this.isIncluindoTabela = false;
    this.comissaoTabelaForm.reset();
  }

  salvarComissoesTabela(): void {
    console.log('Salvar SBM:', this.itemsTabelaGrpProduto);
    console.log('Salvar ACY:', this.itemsTabelaAcy);
    console.log('Salvar ACN:', this.itemsTabelaAcn);
    this.poNotification.success('Todas as comissões em lote foram processadas com sucesso!');
    this.comissaoTabelaModal.close();
  }

  carregarComissoesVendedor(codigo: string): void {
    this.comissoesService.getVendedor(codigo).subscribe({
      next: (data: VendedorComissao) => {
        this.vendedorComissoesDados = data;
        if (data && data.ZZA_DESCV) {
          this.comissaoForm.patchValue({ ZZA_DESCV: data.ZZA_DESCV });
        }
      },
      error: () => {
        const nomeVendedor = this.viewSellerForm.get('name')?.value || '';
        this.vendedorComissoesDados = {
          ZZA_CODV: codigo,
          ZZA_DESCV: nomeVendedor,
          itens: []
        };
      }
    });
  }

  resetarFormComissao(nomeVendedor: string = ''): void {
    this.isEditingComissao = false;
    this.comissaoForm.reset({
      ZZA_DESCV: nomeVendedor,
      ZZA_CODP: '',
      ZZA_DESCP: '',
      ZZA_COMIS: 0
    });
  }

  prepararEdicaoComissao(item: ItemComissao): void {
    this.isEditingComissao = true;
    this.comissaoForm.patchValue({
      ZZA_CODP: item.ZZA_CODP,
      ZZA_DESCP: item.ZZA_DESCP,
      ZZA_COMIS: item.ZZA_COMIS
    });
  }

  salvarComissao(): void {
    if (this.comissaoForm.invalid) return;
    const values = this.comissaoForm.getRawValue();

    if (this.isEditingComissao) {
      const payload = {
        ZZA_DESCV: values.ZZA_DESCV,
        ZZA_DESCP: values.ZZA_DESCP,
        ZZA_COMIS: Number(values.ZZA_COMIS)
      };

      this.comissoesService.atualizarRegistro(this.codigoVendedorAtual, values.ZZA_CODP, payload).subscribe({
        next: () => {
          this.poNotification.success('Comissão atualizada com sucesso!');
          this.carregarComissoesVendedor(this.codigoVendedorAtual);
          this.resetarFormComissao(values.ZZA_DESCV);
        },
        error: () => this.poNotification.error('Erro ao atualizar comissão.')
      });
    } else {
      const payload = {
        ZZA_DESCV: values.ZZA_DESCV,
        ZZA_CODP: values.ZZA_CODP,
        ZZA_DESCP: values.ZZA_DESCP,
        ZZA_COMIS: Number(values.ZZA_COMIS)
      };

      this.comissoesService.criarRegistro(this.codigoVendedorAtual, payload).subscribe({
        next: () => {
          this.poNotification.success('Comissão cadastrada com sucesso!');
          this.carregarComissoesVendedor(this.codigoVendedorAtual);
          this.resetarFormComissao(values.ZZA_DESCV);
        },
        error: () => this.poNotification.error('Erro ao cadastrar comissão.')
      });
    }
  }

  excluirComissao(produtoCod: string): void {
    if (confirm(`Deseja excluir a comissão do produto ${produtoCod}?`)) {
      this.comissoesService.deletarRegistro(this.codigoVendedorAtual, produtoCod).subscribe({
        next: () => {
          this.poNotification.success('Comissão excluída com sucesso!');
          this.carregarComissoesVendedor(this.codigoVendedorAtual);
        },
        error: () => this.poNotification.error('Erro ao excluir comissão.')
      });
    }
  }

  openModalForCreate(): void {
    this.isEditing = false;
    this.sellerForm.reset({
      A3_FILIAL: '01',
      A3_MSBLQL: '2',
      A3_TIPO: 'I',
      A3_GERASE2: 'N',
      A3_ACREFIN: 'N',
      A3_DIA: 15,
      A3_DDD: 'F',
      A3_SINCTAF: 'S',
      A3_SINCAGE: 'S',
      A3_SINCCON: 'S',
      A3_PERAGE: 'A',
      A3_PERTAF: 'A',
      A3_TIPVEND: '1',
      A3_TIMEMIN: '30',
      A3_PAIS: '105',
      A3_EST: 'SP',
      A3_BIAGEND: '2',
      A3_BITAREF: '2',
      A3_BICONT: '2',
      A3_BASEIR: '1',
      A3_HAND: '2',
      A3_MODTRF: '3'
    });
    this.carregarMunicipios('SP');
    this.atualizarListaSupervisores('');
    this.sellerModal.open();
  }

  openModalForEdit(seller: Seller): void {
    this.isEditing = true;
    const formValues: any = {};
    Object.keys(seller).forEach(key => {
      const fieldObj = seller[key];
      if (fieldObj && typeof fieldObj === 'object' && 'valor' in fieldObj) {
        formValues[key] = fieldObj.valor;
      } else {
        formValues[key] = fieldObj;
      }
    });

    this.sellerForm.patchValue(formValues);
    const estadoVal = formValues.A3_EST;
    if (estadoVal) this.carregarMunicipios(estadoVal);
    const codigoAtual = formValues.A3_COD || '';
    this.atualizarListaSupervisores(codigoAtual);
    this.sellerModal.open();
  }

  openModalForCopy(seller: Seller): void {
    const sourceCode = seller.A3_COD?.valor || seller.code;
    const sourceName = seller.A3_NOME?.valor || seller.name;

    this.targetSellersList = this.sellers()
      .filter(s => {
        const cod = s.A3_COD?.valor || s.code;
        return cod !== sourceCode;
      })
      .map(s => {
        const cod = s.A3_COD?.valor || s.code;
        const nome = s.A3_NOME?.valor || s.name;
        return { label: `${cod} - ${nome}`, value: cod };
      });

    this.copyProfileForm.reset({
      sourceCode: sourceCode,
      sourceName: sourceName,
      targetSellerCode: ''
    });
    this.copyModal.open();
  }

  confirmCopyProfile(): void {
    if (this.copyProfileForm.invalid) return;
    const sourceCode = this.copyProfileForm.get('sourceCode')?.value;
    const targetCode = this.copyProfileForm.get('targetSellerCode')?.value;

    this.comissoesService.copiarPerfil(sourceCode, targetCode).subscribe({
      next: () => {
        this.poNotification.success(`Perfil copiado com sucesso para o vendedor ${targetCode}!`);
        this.copyModal.close();
        this.loadSellers();
      },
      error: () => this.poNotification.error('Erro ao copiar o perfil do vendedor.')
    });
  }

  saveSeller(): void {
    if (this.sellerForm.invalid) return;
    const rawValues = this.sellerForm.getRawValue();
    const payload: any = {};
    Object.keys(rawValues).forEach(key => { payload[key] = rawValues[key]; });
    const codeVal = payload.A3_COD;

    if (this.isEditing) {
      this.sellerService.updateSeller(codeVal, payload).subscribe({
        next: () => {
          this.poNotification.success('Vendedor atualizado com sucesso!');
          this.sellerModal.close();
          this.loadSellers();
        },
        error: () => this.poNotification.error('Erro ao atualizar vendedor.')
      });
    } else {
      this.sellerService.createSeller(payload).subscribe({
        next: () => {
          this.poNotification.success('Vendedor cadastrado com sucesso!');
          this.sellerModal.close();
          this.loadSellers();
        },
        error: () => this.poNotification.error('Erro ao cadastrar vendedor.')
      });
    }
  }
}