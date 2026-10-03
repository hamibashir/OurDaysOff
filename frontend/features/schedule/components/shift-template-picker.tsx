"use client";

import { ShiftTemplate } from "@/types/api";
import { Plus, Check, Moon, Sparkles } from "lucide-react";

interface ShiftTemplatePickerProps {
  templates: ShiftTemplate[];
  selectedTemplateId: number | null;
  onSelect: (template: ShiftTemplate | null) => void;
  onCreateNew: () => void;
}

export function ShiftTemplatePicker({
  templates,
  selectedTemplateId,
  onSelect,
  onCreateNew,
}: ShiftTemplatePickerProps) {
  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <label className="text-xs font-semibold uppercase tracking-wider text-[#656A6D] flex items-center gap-1.5">
          <Sparkles className="w-3.5 h-3.5 text-[#2B7A72]" />
          Quick Shift Templates
        </label>
        <button
          onClick={onCreateNew}
          className="text-xs text-[#2B7A72] hover:underline font-semibold flex items-center gap-1 transition-colors"
        >
          <Plus className="w-3.5 h-3.5" />
          New Template
        </button>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
        {templates.map((tpl) => {
          const isSelected = selectedTemplateId === tpl.id;

          return (
            <button
              key={tpl.id}
              onClick={() => onSelect(isSelected ? null : tpl)}
              className={`p-3 rounded-xl border text-left transition-all relative flex flex-col justify-between ${
                isSelected
                  ? "bg-[#81D8D0]/18 border-[#81D8D0] text-[#1F2223] ring-1 ring-[#81D8D0] shadow-xs"
                  : "bg-white border-[#E8E5DF] hover:border-[#D8D4CC] text-[#1F2223] shadow-xs"
              }`}
            >
              <div
                className="w-3 h-3 rounded-full mb-2 shadow-xs"
                style={{ backgroundColor: tpl.color || "#81D8D0" }}
              />
              <div>
                <p className="text-xs font-bold text-[#1F2223] flex items-center justify-between">
                  <span>{tpl.name}</span>
                  {tpl.is_overnight && <Moon className="w-3 h-3 text-[#6A3E94]" />}
                </p>
                <p className="text-[11px] text-[#656A6D] font-mono mt-0.5">
                  {tpl.start_time.slice(0, 5)} - {tpl.end_time.slice(0, 5)}
                </p>
              </div>

              {isSelected && (
                <div className="absolute top-2.5 right-2.5 w-4.5 h-4.5 rounded-full bg-[#81D8D0] flex items-center justify-center shadow-xs">
                  <Check className="w-3 h-3 text-[#1D5E57]" />
                </div>
              )}
            </button>
          );
        })}

        {templates.length === 0 && (
          <div className="col-span-full py-4 text-center border border-dashed border-[#E8E5DF] rounded-xl">
            <p className="text-xs text-[#656A6D]">No shift templates created yet. Click &quot;+ New Template&quot; to create standard shift presets.</p>
          </div>
        )}
      </div>
    </div>
  );
}

