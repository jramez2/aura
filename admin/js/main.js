document.addEventListener('DOMContentLoaded', () => {
    // 1. Theme Toggle
    const themeToggle = document.getElementById('themeToggle');
    const themeIcon = document.getElementById('themeIcon');
    const body = document.body;

    themeToggle.addEventListener('click', () => {
        if (body.hasAttribute('data-theme')) {
            body.removeAttribute('data-theme');
            themeIcon.setAttribute('name', 'moon-outline');
            updateChartsTheme('dark');
        } else {
            body.setAttribute('data-theme', 'light');
            themeIcon.setAttribute('name', 'sunny-outline');
            updateChartsTheme('light');
        }
    });

    // 2. Variables for Charts
    let userChart, expensesChart;
    const getChartOptions = (isDark) => {
        const textColor = isDark ? '#a1a1aa' : '#71717a';
        const gridColor = isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)';
        return { textColor, gridColor };
    };

    const updateChartsTheme = (theme) => {
        if (!userChart || !expensesChart) return;
        const isDark = theme === 'dark';
        const colors = getChartOptions(isDark);

        userChart.options.scales.x.ticks.color = colors.textColor;
        userChart.options.scales.y.ticks.color = colors.textColor;
        userChart.options.scales.y.grid.color = colors.gridColor;
        userChart.update();

        expensesChart.options.plugins.legend.labels.color = colors.textColor;
        expensesChart.update();
    };

    // 3. Fetch API Data
    const API_URL = '../api/v1/admin/dashboard';

    fetch(API_URL)
        .then(response => response.json())
        .then(res => {
            if (res.status === 'success') {
                const data = res.data;
                
                // --- A) Actualizar Métricas ---
                document.getElementById('totalUsersCount').setAttribute('data-target', data.metrics.total_users);
                document.getElementById('totalExpensesCount').setAttribute('data-target', data.metrics.total_expenses);
                document.getElementById('mrrCount').setAttribute('data-target', data.metrics.mrr);
                
                // Iniciar animación de contadores
                startCounters();

                // --- B) Iniciar Gráficos ---
                initCharts(data.charts.userGrowth, data.charts.expensesCategories, data.charts.expensesLabels);

                // --- C) Llenar Tabla ---
                populateTable(data.recent_users);
            }
        })
        .catch(err => {
            console.error("Error cargando API:", err);
            // Mostrar un error visual elegante (Opcional)
        });

    function startCounters() {
        const counters = document.querySelectorAll('.counter, .currency-counter');
        const speed = 200;

        counters.forEach(counter => {
            const updateCount = () => {
                const target = +counter.getAttribute('data-target');
                const count = +counter.innerText.replace(/[^0-9.-]+/g,"");
                if(count === 0) counter.innerText = "0";
                const inc = target / speed;

                if (count < target) {
                    let current = Math.ceil(count + inc);
                    if(counter.classList.contains('currency-counter')) {
                       counter.innerText = '$' + current.toLocaleString();
                    } else {
                       counter.innerText = current.toLocaleString();
                    }
                    setTimeout(updateCount, 15);
                } else {
                    if(counter.classList.contains('currency-counter')) {
                       counter.innerText = '$' + target.toLocaleString();
                    } else {
                       counter.innerText = target.toLocaleString();
                    }
                }
            };
            updateCount();
        });
    }

    function initCharts(userGrowthData, expensesCategories, expensesLabels) {
        const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul'];
        const isDark = !body.hasAttribute('data-theme');
        const colors = getChartOptions(isDark);

        const ctxUsers = document.getElementById('userGrowthChart').getContext('2d');
        const gradient = ctxUsers.createLinearGradient(0, 0, 0, 400);
        gradient.addColorStop(0, 'rgba(99, 102, 241, 0.5)');
        gradient.addColorStop(1, 'rgba(99, 102, 241, 0.0)');

        userChart = new Chart(ctxUsers, {
            type: 'line',
            data: {
                labels: meses,
                datasets: [{
                    label: 'Usuarios Registrados',
                    data: userGrowthData,
                    borderColor: '#6366f1',
                    borderWidth: 3,
                    backgroundColor: gradient,
                    fill: true,
                    tension: 0.4,
                    pointBackgroundColor: '#ffffff',
                    pointBorderColor: '#6366f1',
                    pointBorderWidth: 2,
                    pointRadius: 4,
                    pointHoverRadius: 6
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    x: { grid: { display: false }, ticks: { color: colors.textColor } },
                    y: { grid: { color: colors.gridColor, drawBorder: false }, ticks: { color: colors.textColor } }
                }
            }
        });

        const ctxExpenses = document.getElementById('expensesDistributionChart').getContext('2d');
        expensesChart = new Chart(ctxExpenses, {
            type: 'doughnut',
            data: {
                labels: expensesLabels,
                datasets: [{
                    data: expensesCategories,
                    backgroundColor: ['#6366f1', '#8b5cf6', '#10b981', '#f59e0b', '#ef4444', '#ec4899', '#06b6d4'],
                    borderWidth: 0,
                    hoverOffset: 4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '75%',
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: { color: colors.textColor, usePointStyle: true, padding: 20 }
                    }
                }
            }
        });
    }

    function populateTable(recentUsers) {
        const tbody = document.getElementById('recentUsersTable');
        tbody.innerHTML = '';
        
        recentUsers.forEach(user => {
            const tr = document.createElement('tr');
            const planClass = user.plan === 'Premium' ? 'premium' : '';
            const statusClass = user.status === 'Activo' ? 'active' : 'inactive';

            tr.innerHTML = `
                <td>
                    <strong>${user.name}</strong><br>
                    <span style="font-size: 12px; color: var(--text-secondary);">${user.email}</span>
                </td>
                <td>${user.date}</td>
                <td><span class="plan-badge ${planClass}">${user.plan}</span></td>
                <td>${user.expenses} regs.</td>
                <td><span class="status-badge ${statusClass}">${user.status}</span></td>
            `;
            tbody.appendChild(tr);
        });
    }
});
