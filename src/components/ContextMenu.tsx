// 데스크톱 우클릭 메뉴.
export type CtxItem = { label: string; onClick: () => void };

export default function ContextMenu({
  x,
  y,
  items,
  onClose,
}: {
  x: number;
  y: number;
  items: CtxItem[];
  onClose: () => void;
}) {
  return (
    <div
      className="ctx-backdrop"
      onClick={onClose}
      onContextMenu={(e) => {
        e.preventDefault();
        onClose();
      }}
    >
      <div className="ctx-menu" style={{ left: x, top: y }} onClick={(e) => e.stopPropagation()}>
        {items.map((it, i) => (
          <button
            key={i}
            className="ctx-item"
            onClick={() => {
              it.onClick();
              onClose();
            }}
          >
            {it.label}
          </button>
        ))}
      </div>
    </div>
  );
}
