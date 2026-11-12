import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';

/// Tela de Gestão Financeira Coletiva e Transparência Radical do SuperApp Nous.
/// Expõe custos operacionais reais (IA, Internet, Luz), a Caixinha do Novo Computador,
/// o Fundo Comunitário de apoio e a Chave Pix Oficial com prestação de contas soberana.
class GestaoFinanceiraNousView extends StatelessWidget {
  final AppTheme theme;

  const GestaoFinanceiraNousView({
    super.key,
    required this.theme,
  });

  static const String chavePixOficial = 'nousstudios72@gmail.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: const CustomAppBar(
        title: 'Gestão Financeira do Nous',
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _buildCardApresentacao(context),
                const SizedBox(height: 18),
                _buildSecaoCustos(context),
                const SizedBox(height: 18),
                _buildSecaoFundoComunitario(context),
                const SizedBox(height: 18),
                _buildSecaoComputador(context),
                const SizedBox(height: 18),
                _buildSecaoComoApoiar(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardApresentacao(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFFFFB300),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(
                      texto: 'Transparência Radical & Autossustentação',
                      style: theme.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextoRolante(
                      texto: 'Software livre e popular mantido diretamente pelos usuários',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'O Nous não possui investidores corporativos, taxas abusivas ou anúncios. '
            'Para manter as ferramentas abertas e evoluindo, operamos com transparência absoluta '
            'expondo cada centavo necessário para manter as portas abertas.',
            style: theme.getTextStyle(
              fontSize: 13,
              color: theme.textColor.withValues(alpha: 0.9),
            ).copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoCustos(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ehEstreito = constraints.maxWidth < 620;

        final itensCusto = [
          _buildItemCusto(
            titulo: 'Ferramentas de IA',
            descricao: 'APIs, agentes e auxílio de código',
            valorEstimado: 'R\$ 110,00',
            periodo: '/mês',
            icone: Icons.psychology_rounded,
            corIcone: const Color(0xFF9C27B0),
          ),
          _buildItemCusto(
            titulo: 'Conta de Internet',
            descricao: 'Conexão estável e nós de rede',
            valorEstimado: 'R\$ 275,00',
            periodo: '/mês',
            icone: Icons.wifi_rounded,
            corIcone: const Color(0xFF00BCD4),
          ),
          _buildItemCusto(
            titulo: 'Conta de Luz',
            descricao: 'Servidor balcão e máquinas ativas',
            valorEstimado: 'R\$ 400,00',
            periodo: '/mês',
            icone: Icons.bolt_rounded,
            corIcone: const Color(0xFFFF9800),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextoRolante(
                    texto: 'Despesas Mensais de Operação (Total: R\$ 785,00/mês)',
                    style: theme.getTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (ehEstreito)
              Column(
                children: [
                  for (int i = 0; i < itensCusto.length; i++) ...[
                    itensCusto[i],
                    if (i < itensCusto.length - 1) const SizedBox(height: 10),
                  ],
                ],
              )
            else
              Row(
                children: [
                  for (int i = 0; i < itensCusto.length; i++) ...[
                    Expanded(child: itensCusto[i]),
                    if (i < itensCusto.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildItemCusto({
    required String titulo,
    required String descricao,
    required String valorEstimado,
    required String periodo,
    required IconData icone,
    required Color corIcone,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 20, color: corIcone),
              const SizedBox(width: 8),
              Expanded(
                child: TextoRolante(
                  texto: titulo,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            descricao,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ).copyWith(height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                valorEstimado,
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                periodo,
                style: theme.getTextStyle(
                  fontSize: 11,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoFundoComunitario(BuildContext context) {
    const metaMensal = 785.0;
    const saldoAtual = 113.0;
    const progresso = saldoAtual / metaMensal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextoRolante(
                  texto: 'Fundo Comunitário Nous (Despesas)',
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ativo',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(
                      texto: 'Arrecadado neste mês',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'R\$ 113,00',
                      style: theme.getTextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Meta mensal',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'R\$ 785,00',
                    style: theme.getTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 10,
              backgroundColor: theme.borderColor.withValues(alpha: 0.4),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progresso * 100).toStringAsFixed(1)}% das despesas mensais cobertas',
            style: theme.getTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoComputador(BuildContext context) {
    const metaComputador = 12000.0;
    const saldoComputador = 1500.0;
    const progressoComputador = saldoComputador / metaComputador;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.computer_rounded,
                  color: Color(0xFF7C4DFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextoRolante(
                  texto: 'Caixinha do Novo Computador (Nous Studios)',
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Meta Crucial',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7C4DFF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Nossa máquina atual de desenvolvimento já é antiga e lenta para a escala do aplicativo. '
            'Como o Nous Studios desenvolve toda a compilação, testes pesados, banco SQLite e IA local '
            'da rede, precisamos de uma estação de trabalho de máxima qualidade: processador topo de linha, '
            'placa de vídeo dedicada de última geração e no mínimo 64 GB de RAM.',
            style: theme.getTextStyle(
              fontSize: 12,
              color: theme.secondaryTextColor,
            ).copyWith(height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(
                      texto: 'Saldo na Caixinha',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'R\$ 1.500,00',
                      style: theme.getTextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Valor de mercado estimado',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'R\$ 12.000,00',
                    style: theme.getTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressoComputador,
              minHeight: 10,
              backgroundColor: theme.borderColor.withValues(alpha: 0.4),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progressoComputador * 100).toStringAsFixed(1)}% arrecadado para o computador',
            style: theme.getTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoComoApoiar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFF2196F3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextoRolante(
                  texto: 'Como Ajudar a Manter o Nous Vivo',
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Você pode apoiar com qualquer quantia espontânea (R\$ 2, R\$ 5, R\$ 10 ou mais). '
            'Toda doação mantém o projeto independente e soberano.',
            style: theme.getTextStyle(
              fontSize: 12,
              color: theme.secondaryTextColor,
            ).copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Color(0xFFFFB300),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ao enviar o Pix, especifique na mensagem da transferência se sua doação '
                    'é para o "COMPUTADOR" ou para as "DESPESAS DA EMPRESA".',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ).copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final chaveWidget = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chave Pix Oficial',
                      style: theme.getTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextoRolante(
                      texto: chavePixOficial,
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              );

              final botaoCopiar = ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: chavePixOficial));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chave Pix copiada para a área de transferência!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copiar Pix'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.textColor,
                  foregroundColor: theme.backgroundColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
                ),
                child: constraints.maxWidth < 400
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          chaveWidget,
                          const SizedBox(height: 10),
                          botaoCopiar,
                        ],
                      )
                    : Row(
                        children: [
                          chaveWidget,
                          const SizedBox(width: 8),
                          botaoCopiar,
                        ],
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}
