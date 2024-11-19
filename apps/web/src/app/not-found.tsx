import { Button } from '@latitude-data/web-ui'
import { ErrorComponent } from '@latitude-data/web-ui/browser'
import buildMetatags from '$/app/_lib/buildMetatags'
import { ROUTES } from '$/services/routes'
import Link from 'next/link'

export const metadata = buildMetatags({
  title: 'Not found',
})

export default async function GlobalNoFound() {
  return (
    <ErrorComponent
      type='gray'
      message="We couldn't find what you are looking for. Please make sure that the page exists and try again."
      submit={
        <Link href={ROUTES.root}>
          <Button>Go to Homepage</Button>
        </Link>
      }
    />
  )
}
