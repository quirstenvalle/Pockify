import * as React from "react";

const MD = 768;
const LG = 1024;

export function useBreakpoint() {
  const [width, setWidth] = React.useState<number | undefined>(undefined);

  React.useEffect(() => {
    const update = () => setWidth(window.innerWidth);
    update();
    window.addEventListener("resize", update);
    return () => window.removeEventListener("resize", update);
  }, []);

  const w = width ?? 0;
  return {
    width: w,
    isMobile: w < MD,
    isTablet: w >= MD && w < LG,
    isDesktop: w >= LG,
  };
}
