declare module "react-calendar-heatmap" {
  import type { ComponentType, MouseEvent, ReactElement } from "react";

  export interface CalendarHeatmapValue {
    date: string | Date;
    count?: number;
    [key: string]: unknown;
  }

  export interface CalendarHeatmapProps {
    startDate: string | number | Date;
    endDate: string | number | Date;
    values: CalendarHeatmapValue[];
    showMonthLabels?: boolean;
    showWeekdayLabels?: boolean;
    showOutOfRangeDays?: boolean;
    horizontal?: boolean;
    gutterSize?: number;
    onClick?: (value: CalendarHeatmapValue | null) => void;
    onMouseOver?: (event: MouseEvent, value: CalendarHeatmapValue | null) => void;
    onMouseLeave?: (event: MouseEvent, value: CalendarHeatmapValue | null) => void;
    titleForValue?: (value: CalendarHeatmapValue | null) => string;
    tooltipDataAttrs?: Record<string, string> | ((value: CalendarHeatmapValue | null) => Record<string, string>);
    classForValue?: (value: CalendarHeatmapValue | null) => string;
    monthLabels?: string[];
    weekdayLabels?: string[];
    transformDayElement?: (
      element: ReactElement,
      value: CalendarHeatmapValue | null,
      index: number
    ) => ReactElement;
  }

  const CalendarHeatmap: ComponentType<CalendarHeatmapProps>;
  export default CalendarHeatmap;
}
