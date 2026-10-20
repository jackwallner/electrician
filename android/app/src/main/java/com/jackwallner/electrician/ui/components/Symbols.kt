package com.jackwallner.electrician.ui.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.CompareArrows
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.filled.AllInclusive
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Autorenew
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.EditCalendar
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.EventAvailable
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.FilterVintage
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Help
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Paid
import androidx.compose.material.icons.filled.PanTool
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material.icons.filled.TheaterComedy
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.TouchApp
import androidx.compose.material.icons.filled.TrackChanges
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.ViewAgenda
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.DirectionsWalk
import androidx.compose.material.icons.filled.Filter9Plus
import androidx.compose.material.icons.filled.LibraryAdd
import androidx.compose.material.icons.filled.Tablet
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material.icons.outlined.PlayCircle
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * The SF Symbols the iOS app names, mapped to their closest Material icons.
 * Content and room definitions carry the SF name, so this is the one place
 * the two vocabularies meet.
 */
fun symbol(name: String): ImageVector = when (name) {
    "arrow.down.to.line" -> Icons.Filled.VerticalAlignBottom
    "bolt.horizontal.circle.fill", "bolt.fill" -> Icons.Filled.Bolt
    "bolt.shield.fill" -> Icons.Filled.Shield
    "cable.connector" -> Icons.Filled.Cable
    "chart.line.downtrend.xyaxis" -> Icons.AutoMirrored.Filled.TrendingDown
    "checklist" -> Icons.Filled.Checklist
    "cylinder.fill" -> Icons.Filled.Circle
    "fan.fill" -> Icons.Filled.Toys
    "function" -> Icons.Filled.Functions
    "gearshape.2.fill" -> Icons.Filled.SettingsSuggest
    "house.fill" -> Icons.Filled.Home
    "leaf.fill" -> Icons.Filled.Eco
    "list.number" -> Icons.Filled.FormatListNumbered
    "ruler.fill" -> Icons.Filled.Straighten
    "shippingbox.fill" -> Icons.Filled.Inventory2
    "thermometer.medium" -> Icons.Filled.Thermostat
    "wrench.and.screwdriver.fill" -> Icons.Filled.Build
    "map.fill" -> Icons.Filled.Map
    "square.grid.3x3.fill" -> Icons.Filled.GridView
    "menucard.fill", "menucard" -> Icons.AutoMirrored.Filled.MenuBook
    "arrow.triangle.2.circlepath" -> Icons.Filled.Autorenew
    "hand.point.up.left.fill" -> Icons.Filled.TouchApp
    "crown.fill" -> Icons.Filled.WorkspacePremium
    "number.circle.fill" -> Icons.Filled.Filter9Plus
    "shield.lefthalf.filled" -> Icons.Filled.Security
    "hand.draw.fill" -> Icons.Filled.PanTool
    "flame.fill" -> Icons.Filled.LocalFireDepartment
    "checkmark.seal.fill" -> Icons.Filled.Verified
    "play.circle.fill" -> Icons.Filled.PlayCircle
    "play.circle" -> Icons.Outlined.PlayCircle
    "checkmark.circle.fill" -> Icons.Filled.CheckCircle
    "checkmark.circle" -> Icons.Outlined.CheckCircle
    "circle" -> Icons.Outlined.Circle
    "book.fill", "book.closed.fill" -> Icons.AutoMirrored.Filled.MenuBook
    "book" -> Icons.AutoMirrored.Outlined.MenuBook
    "gearshape" -> Icons.Filled.Settings
    "chevron.right" -> Icons.Filled.ChevronRight
    "chevron.left" -> Icons.Filled.ChevronLeft
    "chevron.down" -> Icons.Filled.ExpandMore
    "lock.fill" -> Icons.Filled.Lock
    "infinity" -> Icons.Filled.AllInclusive
    "calendar.badge.clock" -> Icons.Filled.EditCalendar
    "calendar" -> Icons.Filled.CalendarMonth
    "calendar.badge.checkmark" -> Icons.Filled.EventAvailable
    "person.2.fill" -> Icons.Filled.People
    "person.3.fill" -> Icons.Filled.Groups
    "timer" -> Icons.Filled.Timer
    "arrow.trianglehead.counterclockwise" -> Icons.Filled.Replay
    "sparkles", "sparkle" -> Icons.Filled.AutoAwesome
    "circle.dotted" -> Icons.Outlined.Circle
    "star.fill" -> Icons.Filled.Star
    "star" -> Icons.Filled.StarBorder
    "rectangle.stack.fill" -> Icons.Filled.ViewAgenda
    "questionmark.circle.fill" -> Icons.Filled.Help
    "arrow.left.arrow.right" -> Icons.AutoMirrored.Filled.CompareArrows
    "flag.checkered" -> Icons.Filled.Flag
    "lightbulb.fill" -> Icons.Filled.Lightbulb
    "xmark.circle.fill" -> Icons.Filled.Cancel
    "xmark" -> Icons.Filled.Close
    "hand.tap.fill" -> Icons.Filled.TouchApp
    "arrow.uturn.backward" -> Icons.AutoMirrored.Filled.Undo
    "graduationcap.fill" -> Icons.Filled.School
    "target" -> Icons.Filled.TrackChanges
    "scope" -> Icons.Filled.GpsFixed
    "chart.bar.fill" -> Icons.Filled.BarChart
    "magnifyingglass" -> Icons.Filled.Search
    "exclamationmark.triangle.fill" -> Icons.Filled.Warning
    "square.and.arrow.up" -> Icons.Filled.Share
    "envelope.fill" -> Icons.Filled.Email
    "dollarsign.circle.fill" -> Icons.Filled.Paid
    "ipad.landscape" -> Icons.Filled.Tablet
    "plus.rectangle.on.folder.fill" -> Icons.Filled.LibraryAdd
    "figure.walk" -> Icons.Filled.DirectionsWalk
    "tray" -> Icons.Filled.Inbox
    "doc.on.doc" -> Icons.Filled.ContentCopy
    "camera.macro" -> Icons.Filled.FilterVintage
    "theatermasks.fill" -> Icons.Filled.TheaterComedy
    "back" -> Icons.AutoMirrored.Filled.ArrowBack
    else -> Icons.Filled.Star
}
