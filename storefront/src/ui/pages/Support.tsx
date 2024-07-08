import { SupportWithProviders } from "../Support";
import { RequireAuth } from "../RequireAuth";

export const SupportPage = () => {
  return (
    <RequireAuth>
      <SupportWithProviders />
    </RequireAuth>
  );
};
