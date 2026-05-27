import { useCallback, useEffect, useMemo, useRef, useState } from "react"
import Chart from 'chart.js/auto';
import { DisplayCurrency, GetCurrencyString } from "../casino/Casino";
import { useConfig } from "@/providers/config";
import { Translate } from "@/providers/locale/Locale";
import { useNuiEvent } from "@/providers/nui/useNui";
import { fetchNui } from "@/providers/nui/fetchNui";
import EmployeesTab from "./EmployeesTab";

type CasinoTransaction = {
    id?: number;
    origin: {
        identifier: string;
        name: string;
    },
    type: string;
    amount: number;
    datetime: number;
}

// Transaction types the backend emits. Kept in sync with AddCasinoTransaction
// call sites in modules/*/server.lua. Order here drives the dropdown order.
const TRANSACTION_TYPES = [
    "management_deposit",
    "management_withdraw",
    "deposit",
    "withdraw",
    "purchase",
    "luckywheel_withdraw",
    "vip",
] as const;

const PAGE_SIZE = 50;

type CasinoSettings = {
    [key: string]: any;
}

type ManagementTransfer = {
    type: string,
    balanceType: "balance" | "marked_balance",
    amount: number,
}

// === Display: Transactions (paged, searchable, sortable, infinite-scroll) ===
type TxSortBy = "datetime" | "amount" | "name" | "type";
type TxSortDir = "asc" | "desc";

function TransactionRow({transaction, animIndex}: {transaction: CasinoTransaction, animIndex: number}) {
    const isWithdraw = transaction.type.includes("withdraw");
    return (
        <div
            className="tx-row fade-in"
            style={{animationDelay: `${Math.min(animIndex, 8) * 24}ms`}}
        >
            <div className="flex flex-row justify-between items-baseline gap-3">
                <div className="font-display text-base text-foreground truncate">{transaction.origin.name}</div>
                <div
                    className="font-numeric text-sm font-semibold whitespace-nowrap"
                    style={{ color: isWithdraw ? "hsl(0 55% 65%)" : "hsl(90 35% 65%)" }}
                >
                    {isWithdraw ? "−" : "+"} <DisplayCurrency value={Math.abs(transaction.amount)} />
                </div>
            </div>
            <div className="flex flex-row justify-between items-center mt-1.5">
                <div className="text-[10px] text-muted-foreground/80 font-numeric tracking-wide">
                    {new Date(transaction.datetime * 1000).toLocaleString(undefined, {
                        month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
                    })}
                </div>
                <div className="eyebrow-muted">
                    <Translate id={"casino_manage_" + transaction.type}/>
                </div>
            </div>
        </div>
    );
}

function DisplayTransactions({casinoId}: {casinoId: number}) {
    const [rows, setRows] = useState<CasinoTransaction[]>([]);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(false);
    const [reachedEnd, setReachedEnd] = useState(false);

    const [search, setSearch] = useState("");
    const [searchDebounced, setSearchDebounced] = useState("");
    const [typeFilter, setTypeFilter] = useState("");
    const [sortBy, setSortBy] = useState<TxSortBy>("datetime");
    const [sortDir, setSortDir] = useState<TxSortDir>("desc");

    const scrollerRef = useRef<HTMLDivElement>(null);
    // Each query carries a sequence number so a late response from a stale
    // filter combination can't overwrite the current view.
    const reqSeq = useRef(0);

    // Debounce the search input — 250ms is long enough that fast typing
    // doesn't flood the server and short enough that it still feels live.
    useEffect(() => {
        const timer = setTimeout(() => setSearchDebounced(search), 250);
        return () => clearTimeout(timer);
    }, [search]);

    const fetchPage = useCallback((offset: number, replace: boolean) => {
        const seq = ++reqSeq.current;
        setLoading(true);
        fetchNui<{ rows: CasinoTransaction[], total: number }>("getCasinoTransactions", {
            offset,
            limit: PAGE_SIZE,
            search: searchDebounced,
            type: typeFilter,
            sortBy,
            sortDir,
        }).then((res) => {
            if (seq !== reqSeq.current) return;
            const incoming = res?.rows ?? [];
            const nextTotal = res?.total ?? 0;
            setTotal(nextTotal);
            setRows((prev) => replace ? incoming : [...prev, ...incoming]);
            // Stop firing more requests once we've covered everything the
            // server told us exists for this filter combo.
            setReachedEnd((replace ? incoming.length : (rows.length + incoming.length)) >= nextTotal);
            setLoading(false);
        }).catch(() => {
            if (seq !== reqSeq.current) return;
            setLoading(false);
        });
    }, [searchDebounced, typeFilter, sortBy, sortDir, rows.length]);

    // Re-fetch from the top whenever any filter/sort changes.
    useEffect(() => {
        if (scrollerRef.current) scrollerRef.current.scrollTop = 0;
        setReachedEnd(false);
        fetchPage(0, true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [searchDebounced, typeFilter, sortBy, sortDir, casinoId]);

    // Live single-row prepend from server push. Only counts if the row
    // matches the current filters; otherwise just bump the total so the
    // "showing N of M" counter stays honest.
    useNuiEvent("newCasinoTransaction", (data: any) => {
        if (data.casinoId !== casinoId || !data.transaction) return;
        const tx: CasinoTransaction = data.transaction;
        const matchesSearch = !searchDebounced
            || tx.origin.name.toLowerCase().includes(searchDebounced.toLowerCase())
            || tx.type.toLowerCase().includes(searchDebounced.toLowerCase());
        const matchesType = !typeFilter || tx.type === typeFilter;
        setTotal((t) => t + 1);
        if (matchesSearch && matchesType && sortBy === "datetime" && sortDir === "desc") {
            // Only prepend visually when the sort makes "newest at top" the
            // natural slot. Any other sort would need a re-sort pass; we
            // instead let the existing rows stand and the next page request
            // pick up the new row in the right spot.
            setRows((prev) => [tx, ...prev]);
        }
    });

    const onScroll = (e: React.UIEvent<HTMLDivElement>) => {
        if (loading || reachedEnd) return;
        const el = e.currentTarget;
        // Pre-fetch when we get within ~200px of the bottom so scrolling
        // never feels like it stops to wait for the network.
        if (el.scrollHeight - el.scrollTop - el.clientHeight < 200) {
            fetchPage(rows.length, false);
        }
    };

    const empty = !loading && rows.length === 0;

    return (
        <div className="flex flex-col h-full min-h-0 gap-3">
            <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search by player or type…"
                className="field w-full text-xs"
            />
            <div className="flex flex-row gap-2 items-center text-[10px] text-muted-foreground/80">
                <select
                    value={typeFilter}
                    onChange={(e) => setTypeFilter(e.target.value)}
                    className="field text-xs flex-1 min-w-0"
                >
                    <option value="">All types</option>
                    {TRANSACTION_TYPES.map((t) => (
                        <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>
                    ))}
                </select>
                <select
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value as TxSortBy)}
                    className="field text-xs flex-1 min-w-0"
                >
                    <option value="datetime">Date</option>
                    <option value="amount">Amount</option>
                    <option value="name">Player</option>
                    <option value="type">Type</option>
                </select>
                <button
                    type="button"
                    className="field text-xs cursor-pointer whitespace-nowrap leading-none"
                    onClick={() => setSortDir((d) => d === "asc" ? "desc" : "asc")}
                    title="Toggle sort direction"
                >
                    {sortDir === "desc" ? "↓" : "↑"}
                </button>
                <span className="font-numeric whitespace-nowrap">
                    {rows.length} / {total}
                </span>
            </div>
            <div
                ref={scrollerRef}
                onScroll={onScroll}
                className="flex flex-col flex-1 min-h-0 overflow-y-auto pr-1"
            >
                {empty ? (
                    <div className="flex flex-col items-center justify-center py-20 gap-3">
                        <div className="font-display italic text-4xl text-primary/40 leading-none">∅</div>
                        <div className="eyebrow-muted">No Activity Recorded</div>
                        <div className="text-xs text-muted-foreground max-w-[220px] text-center font-display italic">
                            {searchDebounced || typeFilter
                                ? "No transactions match the current filters."
                                : "Cash movement through this house will appear here."}
                        </div>
                    </div>
                ) : (
                    <>
                        {rows.map((tx, i) => (
                            <TransactionRow
                                key={tx.id ?? `${tx.datetime}-${i}`}
                                transaction={tx}
                                animIndex={i}
                            />
                        ))}
                        {loading && (
                            <div className="text-[10px] text-muted-foreground/60 text-center py-3 italic">
                                Loading…
                            </div>
                        )}
                        {!loading && reachedEnd && rows.length > 0 && (
                            <div className="text-[10px] text-muted-foreground/40 text-center py-3 italic">
                                End of history
                            </div>
                        )}
                    </>
                )}
            </div>
        </div>
    );
}

// === Display: Settings ===
function DisplaySettings({casinoId, settings}: {casinoId: number, settings: CasinoSettings}) {
    const {config} = useConfig();
    const [settingsState, setSettingsState] = useState<CasinoSettings>(settings);
    const settingsConfig = [
        {variable: "moneyExchangeRate", type: "range", min: 1, max: 100, default: 100, step: 1},
        {variable: "dirtyExchangeRate", type: "range", min: 1, max: 100, default: 75, step: 1},
        {variable: "vipPrice", type: "priceRange", min: 0, max: (config.maxVipPrice || 1000000), default: (config.maxVipPrice || 1000000) / 100, step: (config.maxVipPrice || 1000000) / 100},
        {variable: "isOpen", type: "checkbox", default: true},
    ];

    useEffect(() => {
        const newSettings: CasinoSettings = {};
        settingsConfig.forEach((setting) => {
            newSettings[setting.variable] = settingsState[setting.variable] != undefined ? settingsState[setting.variable] : setting.default;
        });
        setSettingsState(newSettings);
    }, [settings]);

    useNuiEvent("updateCasinoSetting", (data: any) => {
        if (data.casinoId !== casinoId) return;
        setSettingsState((prevState) => ({
            ...prevState,
            [data.variable]: data.value,
        }));
    });

    return (
        <div className="flex flex-col gap-5 h-full overflow-y-auto pr-1">
            {settingsConfig.map((setting, settingIndex) => (
                <div key={settingIndex} className="fade-in" style={{animationDelay: `${settingIndex * 60}ms`}}>
                    {setting.type.toLowerCase().includes("range") && (
                        <div className="flex flex-col gap-3">
                            <div className="flex flex-col gap-1">
                                <div className="flex flex-row w-full justify-between items-baseline gap-3">
                                    <div className="font-display text-[15px] text-foreground">
                                        <Translate id={"casino_manage_" + setting.variable}/>
                                    </div>
                                    <div className="font-numeric text-sm font-semibold text-primary">
                                        {setting.type == "range" && (settingsState[setting.variable] + "%")}
                                        {setting.type == "priceRange" && <DisplayCurrency value={settingsState[setting.variable]} />}
                                    </div>
                                </div>
                                <div className="text-[11px] text-muted-foreground/80 leading-relaxed">
                                    <Translate id={"casino_manage_" + setting.variable + "_desc"}/>
                                </div>
                            </div>
                            <input
                                className="gold-slider"
                                type="range"
                                min={setting.min}
                                max={setting.max}
                                step={setting.step}
                                value={settingsState[setting.variable]}
                                onMouseUp={() => {
                                    fetchNui("updateCasinoSetting", {
                                        casinoId: casinoId,
                                        variable: setting.variable,
                                        value: settingsState[setting.variable],
                                    });
                                }}
                                onChange={(e) => {
                                    const newValue = parseInt(e.target.value);
                                    setSettingsState((prevState) => ({
                                        ...prevState,
                                        [setting.variable]: newValue,
                                    }));
                                }}
                            />
                        </div>
                    )}
                    {setting.type.toLowerCase().includes("checkbox") && (
                        <label className="flex flex-row justify-between items-center w-full cursor-pointer group">
                            <div className="flex flex-col gap-0.5">
                                <div className="font-display text-[15px] text-foreground">
                                    <Translate id={"casino_manage_" + setting.variable}/>
                                </div>
                                <div className="text-[11px] text-muted-foreground/80">
                                    {settingsState[setting.variable] ? "House is open" : "House is closed"}
                                </div>
                            </div>
                            <ToggleSwitch
                                checked={!!settingsState[setting.variable]}
                                onChange={(checked) => {
                                    setSettingsState((prev) => ({...prev, [setting.variable]: checked}));
                                    fetchNui("updateCasinoSetting", {
                                        casinoId: casinoId,
                                        variable: setting.variable,
                                        value: checked,
                                    });
                                }}
                            />
                        </label>
                    )}
                </div>
            ))}
            <div className="hairline mt-2" />
            <button
                className="btn-ghost w-full inline-flex items-center justify-center gap-2"
                onClick={() => fetchNui("openCasinoEditor", { casinoId })}
            >
                <span className="text-[10px]">◆</span>
                <Translate id={"casino_manage_editor"}/>
            </button>
        </div>
    );
}

// === Custom toggle switch (gold) ===
function ToggleSwitch({checked, onChange}: {checked: boolean, onChange: (v: boolean) => void}) {
    return (
        <button
            type="button"
            onClick={() => onChange(!checked)}
            className="relative w-11 h-6 rounded-full transition-colors duration-300"
            style={{
                background: checked
                    ? 'linear-gradient(90deg, #A88332, #D4AF37)'
                    : 'hsl(26 14% 14%)',
                border: `1px solid ${checked ? 'hsl(41 55% 35%)' : 'hsl(30 18% 16%)'}`,
            }}
        >
            <span
                className="absolute top-0.5 w-4 h-4 rounded-full transition-transform duration-300"
                style={{
                    left: '2px',
                    transform: checked ? 'translateX(20px)' : 'translateX(0)',
                    background: checked ? '#F4E9D8' : 'hsl(36 16% 60%)',
                    boxShadow: '0 1px 2px hsl(0 0% 0% / 0.5)',
                }}
            />
        </button>
    );
}

// === Helpers for chart ===
type WeeklyBucket = { date: string; profit: number };

// Server returns YYYY-MM-DD strings; turn them into the short user-locale
// label the axis displays (e.g. "May 17").
function formatBucketLabel(iso: string) {
    // Construct without a TZ offset so it lands on the calendar day the
    // server intended, regardless of the client's locale TZ.
    const [y, m, d] = iso.split("-").map((n) => parseInt(n, 10));
    if (!y || !m || !d) return iso;
    return new Date(y, m - 1, d).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

// === Main Management component ===
function Management({info}: {info: any}) {
    const managementGraphRef = useRef<HTMLCanvasElement>(null);
    // Right panel's height is synced to the left column via ResizeObserver
    // below. Pure-CSS approaches (absolute fill, grid stretch) kept being
    // defeated by some interaction with the inner flex/scroll chain, so this
    // is the explicit version: measure left, set right.
    const leftColumnRef = useRef<HTMLDivElement>(null);
    const [rightPanelHeight, setRightPanelHeight] = useState<number | null>(null);
    const {config} = useConfig();
    const [money, setMoney] = useState<number>(info.balance || 0);
    const [dirty_money, setDirtyMoney] = useState<number>(info.marked_balance || 0);
    const [settings] = useState<CasinoSettings>(info.settings || {});
    const [transfer, setTransfer] = useState<ManagementTransfer | null>(null);
    const [sidebarSection, setSidebarSection] = useState("transactions");
    const [weeklyBuckets, setWeeklyBuckets] = useState<WeeklyBucket[]>([]);

    const weeklyProfit = useMemo(() => weeklyBuckets.map((b) => b.profit), [weeklyBuckets]);
    const weeklyLabels = useMemo(() => weeklyBuckets.map((b) => formatBucketLabel(b.date)), [weeklyBuckets]);
    const profit = useMemo(() => weeklyProfit.reduce((acc, v) => acc + v, 0), [weeklyProfit]);

    // Pull the 7-day aggregate from the server. Refresh whenever a new
    // transaction arrives so the chart reflects live activity without
    // having to ship the whole history client-side.
    const refreshWeekly = useCallback(() => {
        fetchNui<WeeklyBucket[]>("getCasinoWeeklyProfit", {})
            .then((res) => setWeeklyBuckets(Array.isArray(res) ? res : []))
            .catch(() => {});
    }, []);

    useEffect(() => { refreshWeekly(); }, [info.casinoId, refreshWeekly]);
    useNuiEvent("newCasinoTransaction", (data: any) => {
        if (data.casinoId === info.casinoId) refreshWeekly();
    });
    const isJobOwned = info?.owner_info?.type === "job";
    const sidebarConfig = [
        {id: "transactions", label: <Translate id={"casino_manage_transactions"}/>},
        {id: "settings", label: <Translate id={"casino_manage_settings"}/>},
        ...(isJobOwned ? [{id: "employees", label: <>Employees</>}] : []),
    ];

    useNuiEvent("updateCasinoBalance", (data: any) => {
        if (data.casinoId !== info.casinoId) return;
        setMoney(data.balance);
        setDirtyMoney(data.marked_balance);
    });

    // Keep the right-side card the exact height of the left column (vault +
    // chart). Without this the transactions list either grows the card (when
    // many rows load) or the left grows to match a too-tall right (when
    // fewer). ResizeObserver covers chart-canvas reflows and content changes
    // on either side.
    useEffect(() => {
        const node = leftColumnRef.current;
        if (!node) return;
        const apply = () => setRightPanelHeight(node.getBoundingClientRect().height);
        apply();
        const ro = new ResizeObserver(apply);
        ro.observe(node);
        return () => ro.disconnect();
    }, []);

    const profitColor = profit > 0 ? "hsl(90 35% 65%)" : profit < 0 ? "hsl(0 55% 65%)" : "hsl(38 38% 90%)";

    useEffect(() => {
        if (!managementGraphRef.current) return;
        if (weeklyBuckets.length === 0) return;
        const canvas = managementGraphRef.current;

        const GOLD = 'hsl(41 55% 53%)';
        const LOSS = 'hsl(0 55% 60%)';

        const chart = new Chart(canvas, {
            type: 'line',
            data: {
                labels: weeklyLabels,
                datasets: [{
                    data: weeklyProfit,
                    pointBackgroundColor: (ctx: any) => (ctx.raw as number) < 0 ? LOSS : GOLD,
                    pointBorderColor: 'hsl(24 25% 6%)',
                    pointBorderWidth: 1.5,
                    pointRadius: 3,
                    pointHoverRadius: 5,
                    borderColor: GOLD,
                    borderWidth: 1.5,
                    tension: 0.35,
                    // Anchor the fill to the zero baseline rather than the
                    // bottom of the chart. Without this, a chart that dips
                    // into negative territory fills the whole canvas area
                    // below the line — which makes the negative segment
                    // look like a huge "win" instead of a loss.
                    fill: { target: { value: 0 } },
                    // Recolor any segment that crosses below zero in red so
                    // gains and losses read at a glance.
                    segment: {
                        borderColor: (ctx: any) => {
                            const a = ctx.p0?.parsed?.y ?? 0;
                            const b = ctx.p1?.parsed?.y ?? 0;
                            return (a < 0 && b < 0) ? LOSS : GOLD;
                        },
                    },
                    backgroundColor: (ctx: any) => {
                        const c = ctx.chart.ctx;
                        const area = ctx.chart.chartArea;
                        if (!area) return 'hsla(41, 55%, 53%, 0.18)';
                        // Two-stop gradient that transitions through the
                        // zero line: gold-tinted above, red-tinted below.
                        // Falls back gracefully when the chart is entirely
                        // above or below zero.
                        const yScale = ctx.chart.scales.y;
                        const zeroY = yScale ? yScale.getPixelForValue(0) : area.bottom;
                        const clampedZero = Math.max(area.top, Math.min(area.bottom, zeroY));
                        const gradient = c.createLinearGradient(0, area.top, 0, area.bottom);
                        const zeroStop = (clampedZero - area.top) / (area.bottom - area.top);
                        gradient.addColorStop(0, 'hsla(41, 55%, 53%, 0.28)');
                        gradient.addColorStop(Math.max(0, zeroStop - 0.001), 'hsla(41, 55%, 53%, 0)');
                        gradient.addColorStop(Math.min(1, zeroStop + 0.001), 'hsla(0, 55%, 60%, 0)');
                        gradient.addColorStop(1, 'hsla(0, 55%, 60%, 0.28)');
                        return gradient;
                    },
                }],
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        backgroundColor: 'hsl(24 18% 6%)',
                        borderColor: 'hsl(41 55% 53% / 0.5)',
                        borderWidth: 1,
                        titleColor: 'hsl(41 55% 53%)',
                        bodyColor: 'hsl(38 38% 90%)',
                        titleFont: { family: 'Outfit', size: 10, weight: 600 },
                        bodyFont: { family: 'Outfit', size: 12 },
                        padding: 10,
                        displayColors: false,
                        callbacks: {
                            label: (context) => GetCurrencyString(context.raw as number, config),
                        },
                    },
                },
                scales: {
                    y: {
                        // Always include zero so the baseline guide-line and
                        // segment color split are meaningful even on a week
                        // that's entirely positive (or entirely negative).
                        beginAtZero: false,
                        suggestedMin: Math.min(0, ...weeklyProfit),
                        suggestedMax: Math.max(0, ...weeklyProfit),
                        grid: {
                            color: (ctx: any) =>
                                ctx.tick.value === 0
                                    ? 'hsl(36 16% 45% / 0.55)'
                                    : 'hsl(30 18% 12%)',
                            lineWidth: (ctx: any) => ctx.tick.value === 0 ? 1.2 : 1,
                            drawTicks: false,
                        },
                        border: { display: false },
                        ticks: {
                            color: 'hsl(36 16% 45%)',
                            font: { family: 'Outfit', size: 9 },
                            padding: 6,
                            callback: (value) => GetCurrencyString(value as number, config),
                        },
                    },
                    x: {
                        grid: { display: false },
                        border: { display: false },
                        ticks: {
                            color: 'hsl(36 16% 45%)',
                            font: { family: 'Outfit', size: 9 },
                            padding: 4,
                        },
                    },
                },
                interaction: { intersect: false, mode: 'index' },
            },
        });
        return () => chart.destroy();
    }, [weeklyBuckets, weeklyProfit, weeklyLabels, config]);

    return (
        <div className="salon-root salon-rise absolute top-[50%] left-[50%] translate-x-[-50%] translate-y-[-50%] w-[880px]">
            <div className="relative salon-bg grain rounded-sm" style={{
                border: '1px solid hsl(30 18% 16%)',
                boxShadow: '0 30px 80px -20px hsl(0 0% 0% / 0.7), 0 0 0 1px hsl(41 55% 53% / 0.08)',
            }}>
                <span className="corner-ornament tl" />
                <span className="corner-ornament tr" />
                <span className="corner-ornament bl" />
                <span className="corner-ornament br" />

                {/* Transfer modal */}
                {transfer && (
                    <div className="absolute top-0 left-0 w-full h-full bg-background/85 backdrop-blur-sm flex flex-col items-center justify-center z-10 rounded-sm fade-in">
                        <div className="salon-card relative w-[360px] p-7">
                            <div className="text-center mb-5">
                                <div className="eyebrow mb-2">Transaction</div>
                                <div className="font-display italic text-2xl text-foreground">House Transfer</div>
                                <div className="diamond-divider mt-3"><span className="text-[10px]">◆</span></div>
                            </div>
                            <div className="flex flex-col gap-4">
                                <div className="flex flex-col gap-1.5">
                                    <div className="eyebrow-muted">
                                        <Translate id={"casino_manage_transfer_balancetype"}/>
                                    </div>
                                    <select
                                        value={transfer.balanceType}
                                        onChange={(e) => setTransfer((p: any) => ({...p, balanceType: e.target.value}))}
                                        className="field w-full"
                                    >
                                        <option value="balance"><Translate id={"casino_manage_balance"}/></option>
                                        <option value="marked_balance"><Translate id={"casino_manage_markedbalance"}/></option>
                                    </select>
                                </div>
                                <div className="flex flex-col gap-1.5">
                                    <div className="eyebrow-muted">
                                        <Translate id={"casino_manage_transfer_type"}/>
                                    </div>
                                    <select
                                        value={transfer.type}
                                        onChange={(e) => setTransfer((p: any) => ({...p, type: e.target.value}))}
                                        className="field w-full"
                                    >
                                        <option value="withdraw"><Translate id={"casino_manage_transfer_withdraw"}/></option>
                                        <option value="deposit"><Translate id={"casino_manage_transfer_deposit"}/></option>
                                    </select>
                                </div>
                                <div className="flex flex-col gap-1.5">
                                    <div className="eyebrow-muted">
                                        <Translate id={"casino_manage_transfer_amount"}/>
                                    </div>
                                    <input
                                        type="number"
                                        min={1}
                                        value={transfer.amount}
                                        onChange={(e) => setTransfer((p: any) => ({...p, amount: parseInt(e.target.value) || 0}))}
                                        className="field w-full font-numeric"
                                    />
                                </div>
                                <div className="flex flex-row gap-2 mt-2">
                                    <button
                                        className="btn-ghost flex-1"
                                        onClick={() => setTransfer(null)}
                                    >
                                        <Translate id={"casino_manage_transfer_cancel"}/>
                                    </button>
                                    <button
                                        className="btn-gold flex-1"
                                        onClick={() => {
                                            fetchNui("startCasinoTransfer", {
                                                balanceType: transfer.balanceType,
                                                type: transfer.type,
                                                amount: transfer.amount,
                                            });
                                            setTransfer(null);
                                        }}
                                    >
                                        <Translate id={"casino_manage_transfer"}/>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                )}

                {/* Header ribbon */}
                <div className="flex flex-row items-center justify-between px-6 pt-5 pb-4">
                    <div className="flex flex-col">
                        <div className="eyebrow">Management Salon</div>
                        <div className="font-display italic text-2xl text-foreground leading-tight mt-0.5">
                            {info?.casinoName || info?.name || "House Operations"}
                        </div>
                    </div>
                    <div className="flex items-center gap-2">
                        {isJobOwned && info?.owner_info?.name && (
                            <span className="chip chip-gold">
                                <span className="text-[8px]">◆</span>
                                {info.owner_info.name}
                            </span>
                        )}
                        <span className="chip">
                            ESC to Close
                        </span>
                    </div>
                </div>
                <div className="hairline" />

                {/* Main grid */}
                <div className="grid grid-cols-[1fr_1.15fr] gap-5 p-6">

                    {/* Left column: vault + chart */}
                    <div ref={leftColumnRef} className="flex flex-col gap-5">

                        {/* Vault card */}
                        <div className="salon-card p-5 fade-in stagger-1">
                            <div className="flex items-center justify-between mb-4">
                                <div className="eyebrow">The Vault</div>
                                <div className="text-[9px] text-muted-foreground tracking-[0.2em] uppercase">Live</div>
                            </div>
                            <div className="flex flex-col gap-3">
                                <div className="flex flex-row justify-between items-end">
                                    <div className="flex flex-col">
                                        <div className="eyebrow-muted mb-1">
                                            <Translate id={"casino_manage_balance"}/>
                                        </div>
                                        <div className="font-display text-2xl text-foreground font-numeric" style={{color: "hsl(90 35% 70%)"}}>
                                            <DisplayCurrency value={money} />
                                        </div>
                                    </div>
                                    <div className="text-[10px] text-muted-foreground italic font-display">cash</div>
                                </div>
                                <div className="hairline opacity-60" />
                                <div className="flex flex-row justify-between items-end">
                                    <div className="flex flex-col">
                                        <div className="eyebrow-muted mb-1">
                                            <Translate id={"casino_manage_markedbalance"}/>
                                        </div>
                                        <div className="font-display text-2xl font-numeric" style={{color: "hsl(0 55% 70%)"}}>
                                            <DisplayCurrency value={dirty_money} />
                                        </div>
                                    </div>
                                    <div className="text-[10px] text-muted-foreground italic font-display">marked</div>
                                </div>
                            </div>
                            <button
                                className="btn-gold w-full mt-5 inline-flex items-center justify-center gap-2"
                                onClick={() => setTransfer({type: "deposit", balanceType: "balance", amount: 0})}
                            >
                                <span className="text-[9px]">◆</span>
                                <Translate id={"casino_manage_transfer"}/>
                                <span className="text-[9px]">◆</span>
                            </button>
                        </div>

                        {/* Profit chart card */}
                        <div className="salon-card p-5 fade-in stagger-2">
                            <div className="flex flex-row justify-between items-end mb-4">
                                <div className="flex flex-col">
                                    <div className="eyebrow">
                                        <Translate id={"casino_manage_profit"}/>
                                    </div>
                                    <div className="text-[10px] text-muted-foreground tracking-wider uppercase mt-0.5">7-day takeaway</div>
                                </div>
                                <div className="font-display italic text-2xl font-numeric" style={{color: profitColor}}>
                                    {profit > 0 && "+"}
                                    <DisplayCurrency value={profit} />
                                </div>
                            </div>
                            <div className="relative" style={{height: '160px'}}>
                                <canvas ref={managementGraphRef} />
                            </div>
                        </div>
                    </div>

                    {/* Right column: tabs + content. Height is synced from
                        the left column via the ResizeObserver above, so the
                        scroll container has a definite bound and the panel
                        never grows past the vault+chart stack. */}
                    <div
                        className="salon-card p-5 flex flex-col fade-in stagger-3"
                        style={rightPanelHeight ? { height: rightPanelHeight } : undefined}
                    >
                        <div className="flex flex-row items-center gap-8 pb-2 border-b border-border/50 mb-5">
                            {sidebarConfig.map((section) => (
                                <button
                                    key={section.id}
                                    className="tab-btn"
                                    data-active={sidebarSection === section.id}
                                    onClick={() => setSidebarSection(section.id)}
                                >
                                    {section.label}
                                </button>
                            ))}
                        </div>
                        <div className="flex-1 min-h-0 overflow-hidden">
                            {sidebarSection === "transactions" && (
                                <DisplayTransactions casinoId={info.casinoId} />
                            )}
                            {sidebarSection === "settings" && (
                                <DisplaySettings casinoId={info.casinoId} settings={settings} />
                            )}
                            {sidebarSection === "employees" && isJobOwned && (
                                <EmployeesTab casinoId={info.casinoId} />
                            )}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}

export default function ManagementDisplay() {
    const [managementInfo, setManagementInfo] = useState<any>(null);
    useNuiEvent("setManagementInfo", (data: any) => {
        setManagementInfo(data.info);
    });
    useEffect(() => {
        const handleKeyDown = (event: KeyboardEvent) => {
            if (!managementInfo) return;
            if (event.key === "Escape") {
                fetchNui("exitManagement", {});
            }
        };
        window.addEventListener("keydown", handleKeyDown);
        return () => window.removeEventListener("keydown", handleKeyDown);
    });
    return (
        <>
            {managementInfo && <Management info={managementInfo} />}
        </>
    );
}
