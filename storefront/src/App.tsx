import { ErrorBoundary } from "react-error-boundary";
import { MetaProvider, Title } from "reactjs-meta";

import { ErrorPageFallback } from "./ErrorPageFallback";
import AppBody from "./ui/AppBody";

const App = () => {
  return (
    <MetaProvider>
      <Title>Supafana | Observability for Supabase</Title>
      <ErrorBoundary FallbackComponent={ErrorPageFallback}>
        <AppBody />
      </ErrorBoundary>
    </MetaProvider>
  );
};

export default App;
