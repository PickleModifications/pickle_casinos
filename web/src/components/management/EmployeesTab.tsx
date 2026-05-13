import { useEffect, useState } from "react";
import { fetchNui } from "@/providers/nui/fetchNui";

interface Employee {
    source: number;
    name: string;
    grade: number;
    gradeLabel: string;
    online: boolean;
    isSelf?: boolean;
}

interface Grade {
    level: number;
    label: string;
}

interface NearbyPlayer {
    source: number;
    name: string;
}

function HireNearby({ casinoId, onHire }: { casinoId: number; onHire: (source: number) => void }) {
    const [nearby, setNearby] = useState<NearbyPlayer[]>([]);
    const [loading, setLoading] = useState(false);
    const [scanned, setScanned] = useState(false);

    const refresh = async () => {
        setLoading(true);
        const players = await fetchNui<NearbyPlayer[]>("getNearbyPlayers", { casinoId });
        setNearby(players || []);
        setScanned(true);
        setLoading(false);
    };

    return (
        <div className="flex flex-col gap-2.5">
            <button
                onClick={refresh}
                disabled={loading}
                className="btn-ghost w-full inline-flex items-center justify-center gap-2"
            >
                <span className="text-[10px]">◆</span>
                {loading ? "Scanning the Floor..." : "Scan Nearby Patrons"}
            </button>
            {scanned && nearby.length === 0 && !loading && (
                <div className="text-[11px] text-muted-foreground/70 text-center py-3 italic font-display">
                    No patrons within reach
                </div>
            )}
            {nearby.map((p, idx) => (
                <div
                    key={p.source}
                    className="employee-card fade-in flex items-center justify-between"
                    style={{ animationDelay: `${idx * 40}ms`, padding: '10px 12px' }}
                >
                    <div className="flex flex-col">
                        <span className="font-display text-sm text-foreground leading-tight">{p.name}</span>
                        <span className="eyebrow-muted mt-1">Civilian</span>
                    </div>
                    <button
                        onClick={() => onHire(p.source)}
                        className="btn-gold"
                        style={{ padding: '6px 12px', fontSize: '10px' }}
                    >
                        Hire
                    </button>
                </div>
            ))}
        </div>
    );
}

export default function EmployeesTab({ casinoId }: { casinoId: number }) {
    const [employees, setEmployees] = useState<Employee[]>([]);
    const [grades, setGrades] = useState<Grade[]>([]);
    const [loading, setLoading] = useState(false);

    const load = async () => {
        setLoading(true);
        const [emps, gds] = await Promise.all([
            fetchNui<Employee[]>("getEmployees", { casinoId }),
            fetchNui<Grade[]>("getJobGrades", { casinoId }),
        ]);
        setEmployees(emps || []);
        setGrades(gds || []);
        setLoading(false);
    };

    useEffect(() => {
        load();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [casinoId]);

    const handleSetGrade = async (targetSource: number, grade: number) => {
        await fetchNui("setEmployeeGrade", { casinoId, targetSource, grade });
        load();
    };

    const handleFire = async (targetSource: number) => {
        await fetchNui("fireEmployee", { casinoId, targetSource });
        load();
    };

    const handleHire = async (targetSource: number) => {
        await fetchNui("hirePlayer", { casinoId, targetSource });
        load();
    };

    return (
        <div className="flex flex-col gap-4 h-full overflow-y-auto pr-1">
            <div className="flex flex-row items-center justify-between">
                <div className="flex flex-col">
                    <div className="eyebrow">The Staff</div>
                    <div className="text-[10px] text-muted-foreground tracking-wider uppercase mt-0.5">
                        {loading ? "Consulting roster..." : `${employees.length} on payroll`}
                    </div>
                </div>
                <button
                    onClick={load}
                    disabled={loading}
                    className="btn-ghost"
                    style={{ padding: '6px 12px', fontSize: '9px' }}
                >
                    Refresh
                </button>
            </div>

            {employees.length === 0 && !loading && (
                <div className="flex flex-col items-center justify-center py-12 gap-3">
                    <div className="font-display italic text-4xl text-primary/40 leading-none">∅</div>
                    <div className="eyebrow-muted">Empty Floor</div>
                    <div className="text-xs text-muted-foreground max-w-[220px] text-center font-display italic">
                        Recruit patrons from the floor below.
                    </div>
                </div>
            )}

            <div className="flex flex-col gap-2.5">
                {employees.map((emp, idx) => (
                    <div
                        key={emp.source}
                        className="employee-card fade-in"
                        style={{ animationDelay: `${idx * 40}ms` }}
                    >
                        <div className="flex items-start justify-between gap-3">
                            <div className="flex flex-col min-w-0 flex-1">
                                <div className="font-display text-base text-foreground leading-tight truncate">{emp.name}</div>
                                <div className="flex items-center gap-2 mt-1 flex-wrap">
                                    <span className="chip chip-gold" style={{padding: '2px 6px', fontSize: '9px'}}>
                                        {emp.gradeLabel}
                                    </span>
                                    {emp.isSelf && (
                                        <span className="chip" style={{padding: '2px 6px', fontSize: '9px'}}>
                                            You
                                        </span>
                                    )}
                                </div>
                            </div>
                            {!emp.isSelf && (
                                <button
                                    onClick={() => handleFire(emp.source)}
                                    className="btn-danger"
                                    title="Dismiss employee"
                                >
                                    Dismiss
                                </button>
                            )}
                        </div>
                        {grades.length > 0 && !emp.isSelf && (
                            <div className="flex items-center gap-2 mt-3 pt-3 border-t border-border/40">
                                <span className="eyebrow-muted whitespace-nowrap">Rank</span>
                                <select
                                    value={emp.grade}
                                    onChange={(e) => handleSetGrade(emp.source, parseInt(e.target.value))}
                                    className="field flex-1"
                                    style={{ padding: '6px 10px', fontSize: '12px' }}
                                >
                                    {grades.map((g) => (
                                        <option key={g.level} value={g.level}>
                                            {g.label}
                                        </option>
                                    ))}
                                </select>
                            </div>
                        )}
                    </div>
                ))}
            </div>

            <div className="mt-3 pt-4 border-t border-border/40">
                <div className="diamond-divider mb-3">
                    <span className="eyebrow">Recruit</span>
                </div>
                <HireNearby casinoId={casinoId} onHire={handleHire} />
            </div>
        </div>
    );
}
